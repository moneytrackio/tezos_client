# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Blocks
      def block(block_hash = "head")
        get "chains/main/blocks/#{block_hash}"
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
