class TezosClient

  class RpcInterface

    module Helper

      using CurrencyUtils

      def forge_transaction(branch:,
                            counter:,
                            from:,
                            to:,
                            amount:,
                            fee:,
                            gas_limit:,
                            storage_limit:,
                            parameters: nil)
        content = {
            'branch' => branch,
            'contents' => [
                {
                    'kind' => 'transaction',
                    'amount' => amount.to_satoshi.to_s,
                    'source' => from,
                    'destination' => to,
                    'gas_limit' => gas_limit.to_satoshi.to_s,
                    'storage_limit' => storage_limit.to_satoshi.to_s,
                    'counter' => counter.to_s,
                    'fee' => fee.to_satoshi.to_s
                }
            ]
        }

        if parameters
          content['contents'][0]['parameters'] = parameters
        end

        post('chains/main/blocks/head/helpers/forge/operations', content)
      end

      def run_transaction(branch:,
                          counter:,
                          from:,
                          to:,
                          amount:,
                          fee:,
                          signature:,
                          gas_limit:,
                          storage_limit:,
                          parameters: nil)
        content = {
            'branch' => branch,
            'contents' => [
                {
                    'kind' => 'transaction',
                    'amount' => amount.to_satoshi.to_s,
                    'source' => from,
                    'destination' => to,
                    'gas_limit' => gas_limit.to_satoshi.to_s,
                    'storage_limit' => storage_limit.to_satoshi.to_s,
                    'counter' => counter.to_s,
                    'fee' => fee.to_satoshi.to_s,
                }
            ],
            'signature' => signature
        }

        if parameters
          content['contents'][0]['parameters'] = parameters
        end

        post('chains/main/blocks/head/helpers/scripts/run_operation', content)
      end

      def preapply_transaction(protocol:,
                              branch:,
                              counter:,
                              from:,
                              to:,
                              amount:,
                              fee:,
                              signature:,
                              gas_limit:,
                              storage_limit:,
                              parameters: nil)
        content = {
            'protocol' => protocol,
            'branch' => branch,
            'contents' => [
                {
                    'kind' => 'transaction',
                    'amount' => amount.to_satoshi.to_s,
                    'source' => from,
                    'destination' => to,
                    'gas_limit' => gas_limit.to_satoshi.to_s,
                    'storage_limit' => storage_limit.to_satoshi.to_s,
                    'counter' => counter.to_s,
                    'fee' => fee.to_satoshi.to_s
                }
            ],
            'signature' => signature
        }

        if parameters
          content['contents'][0]['parameters'] = parameters
        end

        res = post('chains/main/blocks/head/helpers/preapply/operations', [content])
        res[0]
      end

      def broadcast_operation(data)
        post('/injection/operation?chain=main', data)
      end
    end
  end
end
