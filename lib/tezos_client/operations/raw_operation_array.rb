# frozen_string_literal: true

class TezosClient
  class RawOperationArray < Operation
    def post_initialize(raw_operations:, **args)
      @raw_operations = raw_operations.clone
    end

    def rpc_operation_args
      @rpc_operation_args ||= begin
        initial_counter = rpc_interface.contract_counter(@args.fetch(:from)) + 1

        raw_operations.map.with_index do |operation, index|
          counter = (initial_counter + index)
          operation.merge(
            counter: counter.to_s
          )
        end
      end
    end

    private
      attr_reader :raw_operations
  end
end
