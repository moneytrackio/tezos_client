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
          gas_limit: args.fetch(:gas_limit).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit).to_satoshi.to_s,
          counter: args.fetch(:counter).to_s,
          fee: args.fetch(:fee).to_satoshi.to_s
        }
        operation[:parameters] = args[:parameters] if args[:parameters]
        operation
      end

      def transactions_operation(args)
        txs_args = args.clone
        initial_counter = txs_args.delete(:counter)
        amounts = txs_args.delete(:amounts)
        amounts.map.with_index do |(destination, amount), index|
          counter = (initial_counter + index)
          transaction_operation(
            amount: amount,
            to: destination,
            counter: counter,
            **txs_args
          )
        end
      end

      def origination_operation(args)
        operation = {
          kind: "origination",
          delegatable: args.fetch(:delegatable),
          spendable: args.fetch(:spendable),
          balance: args.fetch(:amount).to_satoshi.to_s,
          source: args.fetch(:from),
          gas_limit: args.fetch(:gas_limit).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit).to_satoshi.to_s,
          counter: args.fetch(:counter).to_s,
          fee: args.fetch(:fee).to_satoshi.to_s,
          managerPubkey: args.fetch(:manager)
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
          fee: args.fetch(:fee).to_satoshi.to_s,
          counter: args.fetch(:counter).to_s,
          gas_limit: args.fetch(:gas_limit).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit).to_satoshi.to_s,
          public_key: args.fetch(:public_key)
        }
      end

      def operation(args)
        operation_kind = args.fetch(:operation_kind) { raise ArgumentError, ":operation_kind argument missing" }
        send("#{operation_kind}_operation", args)
      end

      def preapply_operation(args)
        res = preapply_operations(operations: contents(args), **args)
        res[0]
      end

      def run_operation(args)
        res = run_operations(operations: contents(args), **args)
        res[0]
      end

      def forge_operation(args)
        forge_operations(operations: contents(args), **args)
      end

      def contents(args)
        operation = operation(args)
        (operation.is_a?(Array)) ? operation : [operation]
      end
    end
  end
end
