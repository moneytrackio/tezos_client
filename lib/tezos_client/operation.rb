
class TezosClient

  class Operation
    include Crypto
    using CurrencyUtils

    attr_accessor :liquidity_interface,
                  :rpc_interface,
                  :base_58_signature,
                  :signed_hex,
                  :from,
                  :operation_args

    def initialize(liquidity_interface:, rpc_interface:, **args)
      @liquidity_interface = liquidity_interface
      @rpc_interface = rpc_interface
      @from = args.fetch(:from) { raise ArgumentError, "Argument :from missing" }
      @secret_key = args[:secret_key]
      @init_args = args
      @signed = false
      initialize_operation_args
    end

    def initialize_operation_args
      raise NotImplementedError.new("#{self.class.name}##{__method__} is an abstract method.")
    end

    def operation_kind
      raise NotImplementedError.new("#{self.class.name}##{__method__} is an abstract method.")
    end

    def branch
      rpc_interface.head_hash
    end

    def counter
      rpc_interface.contract_counter(from) + 1
    end

    def protocol
      rpc_interface.protocols[0]
    end

    def simulate_and_update_limits
      run_result = run

      @operation_args[:gas_limit] = run_result[:consumed_gas] + 0.01
      @operation_args[:storage_limit] = run_result[:consumed_storage]
    end

    def to_hex
      rpc_interface.forge_operation(operation_args)
    end

    def sign
      sign_operation(
        secret_key: @secret_key,
        operation_hex: to_hex
      ) do |base_58_signature, signed_hex|
        @base_58_signature = base_58_signature
        @signed_hex = signed_hex
      end

      @signed = true
    end

    def test_and_broadcast
      # simulate operations and adjust gas limits
      simulate_and_update_limits
      sign
      operation_result = preapply
      op_id = broadcast
      {
        operation_id: op_id,
        operation_result: operation_result
      }
    end

    def run
      rpc_response = rpc_interface.run_operation(**operation_args, signature: RANDOM_SIGNATURE)

      operation_result = ensure_applied!(rpc_response)

      consumed_storage = operation_result.fetch(:paid_storage_size_diff, "0").to_i.from_satoshi
      consumed_gas = operation_result.fetch(:consumed_gas, "0").to_i.from_satoshi

      {
        status: :applied,
        consumed_gas: consumed_gas,
        consumed_storage: consumed_storage,
        operation_result: operation_result
      }
    end

    def preapply
      raise "can not preapply unsigned operations" unless @signed

      res = rpc_interface.preapply_operation(
        **operation_args,
        signature: base_58_signature,
        protocol: protocol)

      ensure_applied!(res)
    end

    def broadcast
      raise "can not preapply unsigned operations" unless @signed
      rpc_interface.broadcast_operation(signed_hex)
    end


    private

    def ensure_applied!(rpc_response)
      operation_result = rpc_response[:metadata][:operation_result]
      status = operation_result[:status]
      raise "Operation status != 'applied': #{status}\n #{rpc_response.pretty_inspect}" if status != "applied"
      operation_result
    end
  end
end