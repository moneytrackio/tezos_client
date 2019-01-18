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
        args[:amounts].map.with_index do |(destination, amount), index|
          {
            kind: "transaction",
            amount: amount.to_satoshi.to_s,
            source: args.fetch(:from),
            destination: destination,
            gas_limit: args.fetch(:gas_limit).to_satoshi.to_s,
            storage_limit: args.fetch(:storage_limit).to_satoshi.to_s,
            counter: (args.fetch(:counter) + index).to_s,
            fee: args.fetch(:fee).to_satoshi.to_s
          }
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

      %w(origination transaction).each do |operation_kind|
        # preapply_transaction, preapply_origination ...
        define_method "preapply_#{operation_kind}" do |args|
          preapply_operation(operation_kind: operation_kind, **args)
        end

        # run_transaction, run_origination ...
        define_method "run_#{operation_kind}" do |args|
          run_operation(operation_kind: operation_kind, **args)
        end

        # forge_transaction, forge_origination ...
        define_method "forge_#{operation_kind}" do |args|
          forge_operation(operation_kind: operation_kind, **args)
        end
      end


      def preapply_operation(args)
        content = {
          protocol: args.fetch(:protocol),
          branch: args.fetch(:branch),
          contents: contents(args),
          signature: args.fetch(:signature)
        }

        res = post("chains/main/blocks/head/helpers/preapply/operations",
                   [content])
        res[0]["contents"][0]
      end

      def run_operation(args)
        content = {
          branch: args.fetch(:branch),
          contents: contents(args),
          signature: args.fetch(:signature)
        }
        res = post("chains/main/blocks/head/helpers/scripts/run_operation", content)
        res["contents"][0]
      end

      def forge_operation(args)
        content = {
          branch: args.fetch(:branch),
          contents: contents(args)
        }
        post("chains/main/blocks/head/helpers/forge/operations", content)
      end

      def broadcast_operation(data)
        post("injection/operation?chain=main", data)
      end

      def contents(args)
        operation = operation(args)
        (operation.is_a?(Array)) ? operation : [operation]
      end
    end
  end
end
