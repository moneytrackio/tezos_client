# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Option < Base
        def encode
          return { prim: "None" } if data.nil?

          {
            prim: "Some",
            args: [
              TezosClient::Tools::HashToMicheline::Base.new(
                data: data,
                type: type[:args][0]
              ).value
            ]
          }
        end
      end
    end
  end
end
