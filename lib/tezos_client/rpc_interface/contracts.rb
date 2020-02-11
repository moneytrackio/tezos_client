# frozen_string_literal: true

class TezosClient
  class RpcInterface
    using CurrencyUtils
    include Crypto

    module Contracts
      def contract_link(contract_id)
        "/chains/main/blocks/head/context/contracts/#{contract_id}"
      end

      def contract_detail(contract_id)
        get contract_link(contract_id)
      end

      def balance(contract_id)
        res = get("#{contract_link(contract_id)}/balance")
        res.to_i.from_satoshi
      end

      def contract_counter(contract_id)
        res = get("#{contract_link(contract_id)}/counter")
        res.to_i
      end

      def contract_manager_key(contract_id)
        get "#{contract_link(contract_id)}/manager_key"
      end

      def contract_storage(contract_id)
        get "#{contract_link(contract_id)}/storage"
      end

      def big_map_value(big_map_id:, key:, type_key:)
        expr_key = encode_script_expr(data: key, type: type_key)

        get "/chains/main/blocks/head/context/big_maps/#{big_map_id}/#{expr_key}"
      end
    end
  end
end
