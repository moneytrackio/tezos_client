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
                   :pending_operations

    def_delegators :client_interface,
                   :gen_keys,
                   :addresses,
                   :import_public_key,
                   :import_secret_key,
                   :known_contracts,
                   :transfer

    def_delegators :liquidity_interface,
                   :get_storage
  end
end
