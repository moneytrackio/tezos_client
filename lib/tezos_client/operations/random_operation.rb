class TezosClient
  class RandomOperation < Operation
    def post_initialize(raw_operations:, **args)
      @raw_operations = raw_operations.clone
    end

    def rpc_operation_args
      @rpc_operation_args ||= begin
        RawOperationArray.new(
          raw_operations: raw_operations,
          secret_key: @args.fetch(:secret_key),
          from: @args.fetch(:from),
          rpc_interface: rpc_interface,
          liquidity_interface: liquidity_interface,
          build_rpc_operation_args: false
        ).rpc_operation_args
      end
    end

    private

    attr_reader :raw_operations
  end
end