class TezosClient
  class OperationArray < Operation

    def post_initialize(operations:, **args)
      @operations = operations.clone
    end

    def rpc_operation_args
      @rpc_operation_args ||= begin
        initial_counter = rpc_interface.contract_counter(@args.fetch(:from)) + 1

        operations.map.with_index do |operation, index|
          counter = (initial_counter + index)
          operation_kind = operation.delete(:kind)

          operation_klass(operation_kind).new(
            operation
              .merge(@args.slice(:from))
              .merge(
                rpc_interface: rpc_interface,
                counter: counter
            )
          ).rpc_operation_args
        end
      end
    end

    private
    attr_reader :operations

    def operation_klass(operation_name)
      "tezos_client/#{operation_name}_operation".camelize.constantize
    end
  end
end