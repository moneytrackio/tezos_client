# frozen_string_literal: true

require "open3"
require "date"

class TezosClient
  class ClientInterface
    module Misc
      def bootstrapped
        call_client("bootstrapped") do |output|
          output_format = /Current head: ([^ ]+) \(timestamp: ([^,]+), validation: (.+)\)/
          res = output_format.match(output)
          head = res[1]
          timestamp = DateTime.parse(res[2])
          validation = DateTime.parse(res[3])

          {
              "block" => head,
              "timestamp" => timestamp,
              "validated_at" => validation
          }
        end
      end
    end
  end
end
