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

      def origination_operation(args)
        {
          kind: "origination",
          delegatable: args.fetch(:delegatable),
          spendable: args.fetch(:spendable),
          balance: args.fetch(:amount).to_satoshi.to_s,
          source: args.fetch(:from),
          gas_limit: args.fetch(:gas_limit).to_satoshi.to_s,
          storage_limit: args.fetch(:storage_limit).to_satoshi.to_s,
          counter: args.fetch(:counter).to_s,
          fee: args.fetch(:fee).to_satoshi.to_s,
          managerPubkey: args.fetch(:manager),
          script: args.fetch(:script)
        }
      end

      %w(origination transaction).each do |operation_type|
        # preapply_transaction, preapply_origination ...
        define_method "preapply_#{operation_type}" do |args|
          operation = send("#{operation_type}_operation", args)

          res = preapply_operation(
            operation: operation,
            protocol: args.fetch(:protocol),
            branch: args.fetch(:branch),
            signature: args.fetch(:signature)
          )

          res["contents"][0]
        end

        # run_transaction, run_origination ...
        define_method "run_#{operation_type}" do |args|
          operation = send("#{operation_type}_operation", args)

          run_operation(
            operation: operation,
            branch: args.fetch(:branch),
            signature: args.fetch(:signature)
          )
        end

        # forge_transaction, forge_origination ...
        define_method "forge_#{operation_type}" do |args|
          operation = send("#{operation_type}_operation", args)
          forge_operation(branch: args.fetch(:branch), operation: operation)
        end
      end


      def preapply_operation(operation:, protocol:, branch:, signature:)
        content = {
          protocol: protocol,
          branch: branch,
          contents: [operation],
          signature: signature
        }

        res = post("chains/main/blocks/head/helpers/preapply/operations",
                   [content])
        res[0]
      end

      def run_operation(branch:, operation:, signature:)
        content = {
          branch: branch,
          contents: [operation],
          signature: signature
        }
        res = post("chains/main/blocks/head/helpers/scripts/run_operation", content)
        res["contents"][0]
      end

      def forge_operation(branch:, operation:)
        content = {
          branch: branch,
          contents: [operation]
        }
        post("chains/main/blocks/head/helpers/forge/operations", content)
      end

      def broadcast_operation(data)
        post("/injection/operation?chain=main", data)
      end
    end
  end
end
