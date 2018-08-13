class TezosClient
  class RpcInterface
    module Context
      def constants
        get '/chains/main/blocks/head/context/constants'
      end

      def head_hash
        get '/chains/main/blocks/head/hash'
      end

      def chain_id
        get '/chains/main/chain_id'
      end

      def protocols
        get '/protocols'
      end

      def protocol
        get '/protocols/main'
      end
    end
  end
end