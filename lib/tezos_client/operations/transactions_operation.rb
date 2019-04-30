class TezosClient
  class TransactionsOperation < Operation
    def rpc_operation_args
      @rpc_operation_args ||= begin
        OperationArray.new(
          operations: operations,
          secret_key: @args.fetch(:secret_key),
          from: @args.fetch(:from),
          rpc_interface: rpc_interface,
          liquidity_interface: liquidity_interface
        ).rpc_operation_args
      end
    end

    def operations
      @args[:amounts].map do |destination, amount|
        {
          kind: :transaction,
          amount: amount,
          to: destination
        }.merge(
          @args.slice(
            :gas_limit,
            :storage_limit,
            :fee
          )
        )
      end
    end
  end
end