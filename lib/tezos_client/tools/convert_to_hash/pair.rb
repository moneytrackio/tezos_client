# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Pair < Base
        def decode
          raise "Not a 'Pair' type" unless normalized_data[:prim] == "Pair"
          raise "Difference detected between data and type \nDATA: #{normalized_data} \nTYPE:#{normalized_type} " unless normalized_data[:args].size == normalized_type[:args].size

          (normalized_data[:args]).zip(normalized_type[:args]).map do |data_n, type_n|
            TezosClient::Tools::ConvertToHash::Base.new(
              data: data_n,
              type: type_n
            ).value
          end.reduce({}, &:merge)
        end

        private
          def normalized_type
            if type[:args].size > 2
              {
                prim: "pair",
                args: [
                  type[:args][0],
                  {
                    prim: "pair",
                    args: type[:args][1..nil]
                  }
                ]
              }
            else
              type
            end
          end

          def expanded_data
            if data.is_a?(Array)
              { prim: "Pair", args: data }
            else
              data
            end
          end

          def normalized_data
            if expanded_data[:args].size > 2
              {
                prim: "Pair",
                args: [
                  expanded_data[:args][0],
                  {
                    prim: "Pair",
                    args: expanded_data[:args][1..nil]
                  }
                ]
              }
            else
              expanded_data
            end
          end
      end
    end
  end
end
