class TezosClient
  class ClientInterface
    # Commands managing keys and accounts
    module Contract
      def known_contracts
        res = call_client('list known contracts')
        res.lines.reduce({}) do |acc, contract_output|
          address_format = /([^:]+): (\w+)/
          res = address_format.match(contract_output)
          acc.merge(res[1] => res[2])
        end
      end
    end
  end
end