# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Option < Base
        def decode
          if data[:prim] == "None"
            nil
          elsif data[:prim] == "Some"
            TezosClient::Tools::ConvertToHash::Base.new(
              data: data[:args][0],
              type: type[:args][0]
            ).value
          end
        end
      end
    end
  end
end
