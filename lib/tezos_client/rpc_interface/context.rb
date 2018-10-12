# frozen_string_literal: true

class TezosClient
  class RpcInterface
    module Context
      def constants
        get "/chains/main/blocks/head/context/constants"
      end

      def head_hash
        get "/chains/main/blocks/head/hash"
      end

      def chain_id
        get "/chains/main/chain_id"
      end

      def protocols
        get "/protocols"
      end

      def protocol
        metadata = get "/chains/main/blocks/head/metadata"
        metadata[:protocol]
      end
    end
  end
end
