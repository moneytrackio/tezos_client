# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Helper
      using CurrencyUtils

      def transaction_operation(args)
        operation = {
          kind: "transaction",
          amount: args.fetch(:amount).to_satoshi.to_s,
          source: args.fetch(:from),
          destination: args.fetch(:to),
          gas_limit: args.fetch(:gas_limit, 0.1).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit, 0.006).to_satoshi.to_s,
          counter: counter(args).to_s,
          fee: args.fetch(:fee, 0.05).to_satoshi.to_s
        }

        if args[:parameters]
          operation[:parameters] = args[:parameters]
        end
        operation
      end

      def origination_operation(args)
        operation = {
          kind: "origination",
          balance: args.fetch(:amount, 0).to_satoshi.to_s,
          source: args.fetch(:from),
          gas_limit: args.fetch(:gas_limit, 0.1).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit, 0.06).to_satoshi.to_s,
          counter: counter(args).to_s,
          fee: args.fetch(:fee, 0.05).to_satoshi.to_s,
        }

        operation[:script] = args[:script] if args[:script]
        operation
      end


      def activate_account_operation(args)
        {
          kind: "activate_account",
          pkh: args.fetch(:pkh),
          secret: args.fetch(:secret)
        }
      end

      def reveal_operation(args)
        {
          kind: "reveal",
          source: args.fetch(:from),
          fee: args.fetch(:fee, 0.05).to_satoshi.to_s,
          counter: counter(args).to_s,
          gas_limit: args.fetch(:gas_limit, 0.1).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit, 0).to_satoshi.to_s,
          public_key: args.fetch(:public_key)
        }
      end

      def counter(args)
        args.fetch(:counter) do
          contract_counter(args.fetch(:from)) + 1
        end
      end

      def preapply_operation(operation:, **options)
        res = preapply_operations(operations: [operation], **options)
        res[0]
      end

      def run_operation(operation:, **options)
        res = run_operations(operations: [operation], **options)
        res[0]
      end

      def forge_operation(operation:, **options)
        forge_operations(operations: [operation], **options)
      end
    end
  end
end
