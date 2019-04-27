class TezosClient
  class OriginationOperation < Operation
    def post_initialize(liquidity_interface:, **args)
      @liquidity_interface = liquidity_interface
    end

    def rpc_operation_args
      @rpc_operation_args ||= rpc_interface.origination_operation(
        operation_args
      )
    end

    private

    attr_reader :liquidity_interface

    def operation_args
      operation_args = @args.slice(
        :delegatable,
        :spendable,
        :amount,
        :from,
        :gas_limit,
        :storage_limit,
        :fee,
        :counter
      )

      if has_script?
        operation_args[:script] = json_script
      end

      operation_args
    end

    def has_script?
      @args.key? :script
    end

    def json_script
      liquidity_interface.origination_script(
        @args.slice(:from, :script, :init_params)
      )
    end
  end
end