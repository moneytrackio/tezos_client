class TezosClient
  class OperationArray < RawOperationArray

    def post_initialize(operations:, **args)
      @raw_operations = operations.map do |operation|
        operation_kind = operation.delete(:kind)
        operation_klass(operation_kind).new(
          operation.merge(
            from: @args.fetch(:from),
            rpc_interface: rpc_interface,
            counter: 0 # will be set by raw_operation_array
          )
        ).rpc_operation_args
      end
    end

    private


    def operation_klass(operation_name)
      "tezos_client/#{operation_name}_operation".camelize.constantize
    end
  end
end