class TezosClient
  class ActivateAccountOperation < Operation

    def initialize_operation_args
      @operation_args = default_args.merge(
        **@init_args,
        operation_kind: operation_kind,
        branch: branch)
    end

    def operation_kind
      :activate_account
    end

    def ensure_applied!(rpc_response)
      balance_updates = rpc_response[:metadata][:balance_updates]
      raise "Operation failed\n #{rpc_response.pretty_inspect}" if balance_updates.nil?
      if block_given?
        yield rpc_response[:metadata]
      else
        rpc_response[:metadata]
      end
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