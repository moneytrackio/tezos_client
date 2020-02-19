# frozen_string_literal: true

class TezosClient
  class ActivateAccountOperation < Operation
    def rpc_operation_args
      @rpc_operation_args ||= rpc_interface.activate_account_operation(
        operation_args
      )
    end

    def operation_args
      {
        pkh: @args.fetch(:pkh),
        secret: @args.fetch(:secret)
      }
    end
  end
end
