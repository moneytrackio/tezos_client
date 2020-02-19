# frozen_string_literal: true

class TezosClient
  class OriginationOperation < Operation
    def rpc_operation_args
      @rpc_operation_args ||= rpc_interface.origination_operation(
        @args.slice(
          :delegatable,
          :spendable,
          :amount,
          :from,
          :gas_limit,
          :storage_limit,
          :fee,
          :counter,
          :script
        )
      )
    end
  end
end
