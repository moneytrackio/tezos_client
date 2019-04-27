class TezosClient
  class TransactionOperation < Operation
    include EncodeUtils

    def rpc_operation_args
      rpc_interface.transaction_operation(
        operation_args
      )
    end

    private

    def operation_args
      operation_args = @args.slice(
        :amount,
        :from,
        :to,
        :gas_limit,
        :storage_limit,
        :fee,
        :counter
      )
      operation_args[:parameters] = parameters if has_parameters?

      operation_args
    end

    def has_parameters?
      @args.key? :parameters
    end

    def parameters
      (@args[:parameters].is_a? String) ? encode_args(@args[:parameters]) : @args[:parameters]
    end
  end
end