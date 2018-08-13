require 'forwardable'

class TezosClient

  module Commands
    extend Forwardable

    def_delegators :rpc_interface,
                   :bootstrapped,
                   :monitor_block,
                   :head_hash,
                   :contract_counter

    def_delegators :client_interface,
                   :gen_keys,
                   :addresses,
                   :import_public_key,
                   :import_secret_key,
                   :known_contracts,
                   :transfer

  end

end