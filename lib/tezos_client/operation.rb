
class TezosClient

  class Operation
    include Crypto
    using CurrencyUtils

    attr_accessor :liquidity_interface,
                  :rpc_interface,
                  :from,
                  :operation_args

    def initialize(liquidity_interface:, rpc_interface:, **args)
      @liquidity_interface = liquidity_interface
      @rpc_interface = rpc_interface
      @from = args.fetch(:from) { raise ArgumentError, "Argument :from missing" }
      @secret_key = args.fetch(:secret_key)
      @init_args = args
      @operation_args = {}
      initialize_operation_args
      @signed_operation_args_h = nil
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

    def remote_counter
      @remote_counter ||= rpc_interface.contract_counter(from) + 1
    end

    def counter
      @counter ||= @init_args.fetch(:counter) { remote_counter }
    end

    def protocol
      rpc_interface.protocol
    end

    def simulate_and_update_limits
      run_result = run

      @operation_args[:gas_limit] = run_result[:consumed_gas] + 0.01
    end

    def to_hex
      rpc_interface.forge_operation(operation_args)
    end

    def sign
      sign_operation(
        secret_key: @secret_key,
        operation_hex: to_hex
      ) do |base_58_signature, signed_hex, _op_id|
        @signed_operation_args_h = operation_args.hash
        @base_58_signature = base_58_signature
        @signed_hex = signed_hex
      end
    end

    def signed?
      @signed_operation_args_h == operation_args.hash
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
      # https://gitlab.com/tezos/tezos/issues/376
      operation_args.merge!(counter: remote_counter)

      # simulate operations and adjust gas limits
      simulate_and_update_limits
      operation_result = preapply

      # https://gitlab.com/tezos/tezos/issues/376
      operation_args.merge!(counter: counter)

      op_id = broadcast
      {
        operation_id: op_id,
        operation_result: operation_result,
        counter: counter
      }
    end

    def run
      rpc_response = rpc_interface.run_operation(**operation_args, signature: base_58_signature)

      consumed_storage = 0
      consumed_gas = 0

      operation_result = ensure_applied!(rpc_response) do |result|
        consumed_storage = (result.dig(:operation_result, :paid_storage_size_diff) || "0").to_i.from_satoshi
        consumed_gas = (result.dig(:operation_result, :consumed_gas) || "0").to_i.from_satoshi

        unless result[:internal_operation_results].nil?
          result[:internal_operation_results].each do |internal_operation_result|
            consumed_gas += (internal_operation_result[:result][:consumed_gas] || "0").to_i.from_satoshi
          end
        end

        result[:operation_result]
      end

      {
        status: :applied,
        consumed_gas: consumed_gas,
        consumed_storage: consumed_storage,
        operation_result: operation_result
      }
    end

    def preapply
      res = rpc_interface.preapply_operation(
        **operation_args,
        signature: base_58_signature,
        protocol: protocol)

      ensure_applied!(res)
    end

    def broadcast
      rpc_interface.broadcast_operation(signed_hex)
    end


    private

    def ensure_applied!(rpc_response)
      operation_result = rpc_response[:metadata][:operation_result]
      status = operation_result[:status]
      raise "Operation status != 'applied': #{status}\n #{rpc_response.pretty_inspect}" if status != "applied"
      if block_given?
        yield rpc_response[:metadata]
      else
        operation_result
      end
    end
  end
end