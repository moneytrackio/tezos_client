# frozen_string_literal: true

require "forwardable"

class TezosClient
  module Commands
    extend Forwardable

    def_delegators :rpc_interface,
                   :bootstrapped,
                   :monitor_block,
                   :head_hash,
                   :contract_counter,
                   :block_header,
                   :block_operations,
                   :block_operation_hashes,
                   :blocks,
                   :balance,
                   :contract_manager_key,
                   :contract_storage,
                   :contract_detail,
                   :pending_operations,
                   :pack_data,
                   :big_map_value

    def_delegators :liquidity_interface,
                   :get_storage,
                   :liquidity_pack_data
  end
end
