# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Helper
      using CurrencyUtils

      def forge_transaction(args)
        operation = {
          'kind' => 'transaction',
          'amount' => args.fetch(:amount).to_satoshi.to_s,
          'source' => args.fetch(:from),
          'destination' => args.fetch(:to),
          'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
          'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
          'counter' => args.fetch(:counter).to_s,
          'fee' => args.fetch(:fee).to_satoshi.to_s
        }
        operation['parameters'] = args[:parameters] if args[:parameters]

        forge_operation(branch: args.fetch(:branch), operation: operation)
      end

      def forge_origination(args)
        operation = {
          'kind' => 'origination',
          'delegatable' => args.fetch(:delegatable),
          'spendable' => args.fetch(:spendable),
          'balance' => args.fetch(:amount).to_satoshi.to_s,
          'source' => args.fetch(:from),
          'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
          'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
          'counter' => args.fetch(:counter).to_s,
          'fee' => args.fetch(:fee).to_satoshi.to_s,
          'managerPubkey' => args.fetch(:manager),
          'script' => args.fetch(:script)
        }

        forge_operation(branch: args.fetch(:branch), operation: operation)
      end

      def forge_operation(branch:, operation:)
        content = {
          'branch' => branch,
          'contents' => [operation]
        }
        post('chains/main/blocks/head/helpers/forge/operations', content)
      end

      def run_operation(branch:, operation:, signature:)
        content = {
          'branch' => branch,
          'contents' => [operation],
          'signature' => signature
        }
        res = post('chains/main/blocks/head/helpers/scripts/run_operation', content)
        res['contents'][0]
      end

      def run_transaction(args)
        operation = {
          'kind' => 'transaction',
          'amount' => args.fetch(:amount).to_satoshi.to_s,
          'source' => args.fetch(:from),
          'destination' => args.fetch(:to),
          'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
          'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
          'counter' => args.fetch(:counter).to_s,
          'fee' => args.fetch(:fee).to_satoshi.to_s
        }

        if args.key? :parameters
          operation['parameters'] = args.fetch(:parameters)
        end

        run_operation(
          operation: operation,
          branch: args.fetch(:branch),
          signature: args.fetch(:signature)
        )
      end

      def run_origination(args)
        operation = {
          'kind' => 'origination',
          'delegatable' => args.fetch(:delegatable),
          'spendable' => args.fetch(:spendable),
          'balance' => args.fetch(:amount).to_satoshi.to_s,
          'source' => args.fetch(:from),
          'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
          'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
          'counter' => args.fetch(:counter).to_s,
          'fee' => args.fetch(:fee).to_satoshi.to_s,
          'managerPubkey' => args.fetch(:manager),
          'script' => args.fetch(:script)
        }

        run_operation(branch: args.fetch(:branch),
                      operation: operation,
                      signature: args.fetch(:signature))
      end

      def preapply_transaction(args)
        operation = {
          'kind' => 'transaction',
          'amount' => args.fetch(:amount).to_satoshi.to_s,
          'source' => args.fetch(:from),
          'destination' => args.fetch(:to),
          'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
          'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
          'counter' => args.fetch(:counter).to_s,
          'fee' => args.fetch(:fee).to_satoshi.to_s
        }

        operation['parameters'] = args.fetch(:parameters) if args.key?(:parameters)

        res = preapply_operation(
          operation: operation,
          protocol: args.fetch(:protocol),
          branch: args.fetch(:branch),
          signature: args.fetch(:signature)
        )

        res['contents'][0]
      end

      def preapply_origination(args)
        operation = {
            'kind' => 'origination',
            'delegatable' => args.fetch(:delegatable),
            'spendable' => args.fetch(:spendable),
            'balance' => args.fetch(:amount).to_satoshi.to_s,
            'source' => args.fetch(:from),
            'gas_limit' => args.fetch(:gas_limit).to_satoshi.to_s,
            'storage_limit' => args.fetch(:storage_limit).to_satoshi.to_s,
            'counter' => args.fetch(:counter).to_s,
            'fee' => args.fetch(:fee).to_satoshi.to_s,
            'managerPubkey' => args.fetch(:manager),
            'script' => args.fetch(:script)
        }

        res = preapply_operation(
          operation: operation,
          protocol: args.fetch(:protocol),
          branch: args.fetch(:branch),
          signature: args.fetch(:signature)
        )
        res['contents'][0]
      end

      def preapply_operation(operation:, protocol:, branch:, signature:)
        content = {
          'protocol' => protocol,
          'branch' => branch,
          'contents' => [operation],
          'signature' => signature
        }

        res = post('chains/main/blocks/head/helpers/preapply/operations',
                   [content])
        res[0]
      end

      def broadcast_operation(data)
        post('/injection/operation?chain=main', data)
      end
    end
  end
end
