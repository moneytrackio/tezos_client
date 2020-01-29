# frozen_string_literal: true

require "base58"
require "rbnacl"
require "digest"
require "money-tree"
require "bip_mnemonic"

class TezosClient
  class RpcInterface
    using CurrencyUtils
    using StringUtils
    include Crypto

    module Contracts
      def contract_link(contract_id)
        "/chains/main/blocks/head/context/contracts/#{contract_id}"
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
        packed_key = pack_data(data: key, type: type_key)
        raw_expr_key = RbNaCl::Hash::Blake2b.digest(packed_key["packed"].to_bin, digest_size: 32).to_hex
        expr_key = encode_tz(:expr, raw_expr_key)

        get "/chains/main/blocks/head/context/big_maps/#{big_map_id}/#{expr_key}"
      end
    end
  end
end
