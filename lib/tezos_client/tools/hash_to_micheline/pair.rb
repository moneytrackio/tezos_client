# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Pair < Base
        def encode
          {
            prim: "Pair",
            args: args
          }
        end

        private
          def args
            type[:args].each_with_index.map do |type, index|
              TezosClient::Tools::HashToMicheline::Base.new(
                data: data_n(index),
                type: type
              ).value
            end
          end

          def args_count
            type[:args].size
          end

          def data_n(n)
            if data.is_a? ::Array
              is_last_arg = n == (args_count - 1)
              # Handle the case when last arg is i Pair, which arguments are the last elements of the data
              if is_last_arg && data.size > args_count
                data.drop(args_count - 1)
              else
                data[n]
              end
            else
              data
            end
          end
      end
    end
  end
end
