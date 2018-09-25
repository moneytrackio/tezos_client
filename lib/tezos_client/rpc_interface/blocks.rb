# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Blocks
      def block(block_hash = "head")
        get "chains/main/blocks/#{block_hash}"
      end

      def blocks(length: 50, head: nil, min_date: nil)
        query = {
          length: length,
          head: head,
          min_date: min_date&.to_datetime&.to_i
        }.compact

        res = get "chains/main/blocks/", query: query
        res[0]
      end

      def block_header(block_hash = "head")
        get "chains/main/blocks/#{block_hash}/header"
      end

      def block_operations(block_hash = "head")
        get "chains/main/blocks/#{block_hash}/operations"
      end

      def block_operation_hashes(block_hash = "head")
        get "chains/main/blocks/#{block_hash}/operation_hashes"
      end
    end
  end
end
