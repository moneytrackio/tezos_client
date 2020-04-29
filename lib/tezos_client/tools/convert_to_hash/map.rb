# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Map < Base
        def decode
          new_map = {}

          data.each do |elem|
            raise "Not a 'Map' type" unless elem[:prim] == "Elt"

            key = TezosClient::Tools::ConvertToHash::Base.new(
              data: elem[:args].first,
              type: type[:args].first
            ).value

            value = TezosClient::Tools::ConvertToHash::Base.new(
              data: elem[:args].second,
              type: type[:args].second
            ).value

            new_map[key] = value
          end

          new_map
        end
      end
    end
  end
end
