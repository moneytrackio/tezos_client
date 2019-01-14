class TezosClient
  class TransactionsOperation < Operation
    include EncodeUtils

    def initialize_operation_args
      @operation_args = default_args.merge(
        **@init_args,
        operation_kind: operation_kind,
        branch: branch,
        counter: counter
      )
    end


    def operation_kind
      :transactions
    end

    private

    def default_args
      {
        gas_limit: 0.1,
        storage_limit: 0.006,
        fee: 0.05
      }
    end
  end
end