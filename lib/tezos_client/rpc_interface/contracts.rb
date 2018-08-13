class TezosClient

  class RpcInterface
    using CurrencyUtils

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

    end

  end
end