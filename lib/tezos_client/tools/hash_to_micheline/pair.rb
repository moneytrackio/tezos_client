# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Pair < Base
        def encode
          {
            prim: "Pair",
            args: [
              TezosClient::Tools::HashToMicheline::Base.new(
                data: data_0,
                type: type[:args][0]
              ).value,
              TezosClient::Tools::HashToMicheline::Base.new(
                data: data_1,
                type: type[:args][1]
              ).value
            ]
          }
        end

        def data_0
          if data.is_a? ::Array
            data[0]
          else
            data
          end
        end

        def data_1
          if data.is_a? ::Array
            if data.size > 2
              data.drop(1)
            else
              data[1]
            end
          else
            data
          end
        end
      end
    end
  end
end
