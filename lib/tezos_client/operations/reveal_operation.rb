class TezosClient
  class RevealOperation < Operation
    def rpc_operation_args
      @rpc_operation_args ||= rpc_interface.reveal_operation(
        @args.slice(:from, :fee, :gas_limit, :storage_limit, :counter, :public_key)
      )
    end
  end
end