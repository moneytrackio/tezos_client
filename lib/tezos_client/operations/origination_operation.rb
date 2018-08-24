class TezosClient
  class OriginationOperation < Operation

    def initialize_operation_args
      operation_args = default_args.merge(
        **@init_args,
        manager: manager,
        operation_kind: operation_kind,
        branch: branch,
        counter: counter)

      if has_script?
        operation_args[:script] = json_script
      end
      @operation_args = operation_args
    end

    def has_script?
      @init_args.key? :script
    end

    def json_script
      liquidity_interface.origination_script(
        @init_args.slice(:from, :script, :init_params)
      )
    end

    def manager
      @init_args.fetch(:manager) { @init_args.fetch(:from) }
    end


    def operation_kind
      :origination
    end

    private

    def default_args
      {
        amount: 0,
        spendable: false,
        delegatable: false,
        gas_limit: 0.1,
        storage_limit: 0.006,
        fee: 0.05
      }
    end
  end
end