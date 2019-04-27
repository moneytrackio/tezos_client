class TezosClient
  class TransactionsOperation < Operation

    def rpc_operation_args
      @rpc_operation_args ||= begin
        initial_counter = rpc_interface.contract_counter(@args.fetch(:from)) + 1

        @args[:amounts].map.with_index do |(destination, amount), index|
          counter = (initial_counter + index)
          TransactionOperation.new(
            @args.slice(
              :from,
              :gas_limit,
              :storage_limit,
              :fee
            ).merge(
              rpc_interface: rpc_interface,
              amount: amount,
              to: destination,
              counter: counter
            )
          ).rpc_operation_args
        end
      end
    end
  end
end