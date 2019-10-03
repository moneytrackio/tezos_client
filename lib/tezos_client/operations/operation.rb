class TezosClient
  class Operation
    delegate :run, :preapply, :test_and_broadcast, :broadcast, :simulate, :signed_hex, to: :operation_mgr

    def initialize(rpc_interface:, **args)
      @rpc_interface = rpc_interface
      @args = args.clone
      post_initialize(**args)
    end

    protected

    attr_reader :rpc_interface, :liquidity_interface

    def rpc_operation_args
      raise NotImplementedError, "#{__method__} is a virtual method"
    end

    def post_initialize(*_args)
    end

    def operation_mgr
      @operation_mgr ||= OperationMgr.new(
        rpc_interface: rpc_interface,
        rpc_operation_args: rpc_operation_args,
        **operation_options)
    end

    def operation_options
      @args.slice(:secret_key, :protocol, :branch, :ignore_counter_error)
    end
  end
end
