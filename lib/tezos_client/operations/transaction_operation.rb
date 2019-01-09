class TezosClient
  class TransactionOperation < Operation
    include EncodeUtils

    def initialize_operation_args
      @operation_args = default_args.merge(
        **@init_args,
        operation_kind: operation_kind,
        branch: branch,
        counter: counter
      )
      if has_parameters?
        @operation_args[:parameters] = parameters
      end
    end

    def has_parameters?
      @init_args.key? :parameters
    end

    def parameters
      (@init_args[:parameters].is_a? String) ? encode_args(@init_args[:parameters]) : @init_args[:parameters]
    end

    def operation_kind
      :transaction
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