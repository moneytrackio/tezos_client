
class TezosClient

  class OperationMgr
    include Crypto
    using CurrencyUtils

    attr_accessor :rpc_interface,
                  :rpc_operation_args

    def initialize(rpc_interface:, rpc_operation_args:, **args)
      @rpc_interface = rpc_interface
      @secret_key = args.fetch(:secret_key)
      @multiple_operations = rpc_operation_args.is_a?(Array)
      @rpc_operation_args = @multiple_operations ? rpc_operation_args : [rpc_operation_args]
      @signed_operation_args_h = nil
      @branch = args[:branch]
      @protocol = args[:protocol]
    end

    def multiple_operations?
      @multiple_operations
    end

    def single_operation?
      !multiple_operations?
    end

    def branch
      @branch ||= rpc_interface.head_hash
    end

    def protocol
      @protocol ||= rpc_interface.protocol
    end

    def simulate_and_update_limits
      run_result = run

      run_result[:operations_result].zip(rpc_operation_args) do |operation_result, rpc_operation_args|
        if rpc_operation_args.key?(:gas_limit)
          rpc_operation_args[:gas_limit] = (operation_result[:consumed_gas].to_i + 0.001.to_satoshi).to_s
        end
      end

      run_result
    end

    def to_hex
      rpc_interface.forge_operations(operations: rpc_operation_args, branch: branch)
    end

    def sign
      sign_operation(
        secret_key: @secret_key,
        operation_hex: to_hex
      ) do |base_58_signature, signed_hex, _op_id|
        @signed_operation_args_h = rpc_operation_args.hash
        @base_58_signature = base_58_signature
        @signed_hex = signed_hex
      end
    end

    def signed?
      @signed_operation_args_h == rpc_operation_args.hash
    end

    def base_58_signature
      sign unless signed?
      @base_58_signature
    end

    def signed_hex
      sign unless signed?
      @signed_hex
    end

    def test_and_broadcast
      # simulate operations and adjust gas limits
      simulate_and_update_limits
      operations_result = preapply

      op_id = broadcast
      {
        operation_id: op_id,
        operations_result: operations_result,
      }
    end

    def run
      rpc_responses = rpc_interface.run_operations(
        operations: rpc_operation_args,
        signature: base_58_signature,
        branch: branch)

      consumed_storage = 0
      consumed_gas = 0

      operations_result = rpc_responses.map do |rpc_response|
        metadata = rpc_response[:metadata]
        ensure_applied!(metadata)
        consumed_storage += compute_consumed_storage(metadata)
        consumed_gas += compute_consumed_gas(metadata)
        metadata[:operation_result]
      end

      {
        status: :applied,
        consumed_gas: consumed_gas,
        consumed_storage: consumed_storage,
        operations_result: operations_result
      }
    end

    def compute_consumed_gas(metadata)
      consumed_gas = (metadata.dig(:operation_result, :consumed_gas) || "0").to_i.from_satoshi

      if metadata.key?(:internal_operation_results)
        metadata[:internal_operation_results].each do |internal_operation_result|
          consumed_gas += (internal_operation_result[:result][:consumed_gas] || "0").to_i.from_satoshi
        end
      end
      consumed_gas
    end

    def compute_consumed_storage(metadata)
      (metadata.dig(:operation_result, :paid_storage_size_diff) || "0").to_i.from_satoshi
    end


    def preapply
      rpc_responses = rpc_interface.preapply_operations(
        operations: rpc_operation_args,
        signature: base_58_signature,
        protocol: protocol,
        branch: branch)

      rpc_responses.map do |rpc_response|
        ensure_applied!(rpc_response[:metadata])
      end
    end

    def broadcast
      rpc_interface.broadcast_operation(signed_hex)
    end

    private

    def ensure_applied!(metadata)
      operation_result = metadata[:operation_result]

      unless operation_result.nil?
        status = operation_result[:status]
        raise "Operation status != 'applied': #{status}\n #{metadata.pretty_inspect}" if status != "applied"
      end

      operation_result
    end
  end
end