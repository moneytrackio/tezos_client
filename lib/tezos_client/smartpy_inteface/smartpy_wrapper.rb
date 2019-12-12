# frozen_string_literal: true

class TezosClient
  class SmartpyInterface
    # Wrapper used to call the tezos-client binary
    module SmartpyWrapper
      def call_smartpy(command)
        cmd = smartpy_cmd + command

        ::Tools::SystemCall.execute(cmd)
      rescue ::TezosClient::SysCallError => e
        raise ::TezosClient::SmartPyError, e
      end

      def smartpy_cmd
        [ "SmartPy.sh" ]
      end
    end
  end
end
