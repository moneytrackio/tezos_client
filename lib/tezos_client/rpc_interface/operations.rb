# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Operations
      using CurrencyUtils

      def preapply_operations(operations:, **options)
        content = {
          protocol: options.fetch(:protocol),
          branch: options.fetch(:branch),
          contents: operations,
          signature: options.fetch(:signature)
        }

        res = post("chains/main/blocks/head/helpers/preapply/operations",
                   [content])
        res[0]["contents"]
      end

      def run_operations(operations:, **options)
        content = {
          operation: {
            branch: options.fetch(:branch),
            contents: operations,
            signature: options.fetch(:signature)
          },
          chain_id: options.fetch(:chain_id)
        }
        res = post("chains/main/blocks/head/helpers/scripts/run_operation", content)
        res["contents"]
      end

      def forge_operations(operations:, **options)
        content = {
          branch: options.fetch(:branch),
          contents: operations
        }
        post("chains/main/blocks/head/helpers/forge/operations", content)
      end

      def broadcast_operation(data)
        post("injection/operation?chain=main", data)
      end

      def pending_operations
        get("chains/main/mempool/pending_operations")
      end

      def pack_data(data:, type:)
        content = {
            data: data,
            type: type
        }
        post("/chains/main/blocks/head/helpers/scripts/pack_data", content)
      end
    end
  end
end
