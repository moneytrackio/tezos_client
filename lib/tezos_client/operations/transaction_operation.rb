# frozen_string_literal: true

class TezosClient
  class TransactionOperation < Operation
    include EncodeUtils

    def rpc_operation_args
      @rpc_operation_args ||= begin
        rpc_interface.transaction_operation(
          operation_args
        )
      end
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
        parameters = @args[:parameters].clone
        if parameters.is_a? String
          {
            entrypoint: "default",
            value: encode_args(@args[:parameters])
          }
        else
          parameters
        end
      end
  end
end
