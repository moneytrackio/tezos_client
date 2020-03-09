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

      def contract_storage_type(contract_id)
        contract = contract_detail(contract_id)
        contract[:script][:code].find { |elem| elem[:prim] == "storage" }[:args].first
      end

      def contract_storage(contract_id)
        get "#{contract_link(contract_id)}/storage"
      end

      def entrypoint(contract_id, entrypoint)
        get("#{contract_link(contract_id)}/entrypoints/#{entrypoint}")
      end

      def big_map_value(big_map_id:, key:, key_type:)
        expr_key = encode_script_expr(data: key, type: key_type)

        get "/chains/main/blocks/head/context/big_maps/#{big_map_id}/#{expr_key}"
      end

      def contract_big_maps(contract_address)
        contract_storage = contract_storage(contract_address)
        storage_type = contract_storage_type(contract_address)

        TezosClient::Tools::FindBigMapsInStorage.run!(
          storage: contract_storage,
          storage_type: storage_type
        )
      end
    end
  end
end
