# frozen_string_literal: true

require "date"

class TezosClient
  class RpcInterface
    module Monitor
      def bootstrapped
        res = get "/monitor/bootstrapped"
        res["timestamp"] = DateTime.parse(res["timestamp"])
        res
      end

      def monitor_block(&block_reader)
        monitor("monitor/heads/main", &block_reader)
      end
    end
  end
end
