# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Pair < Base
        def decode
          raise "Not a 'Pair' type" unless data[:prim] == "Pair"
          raise "Difference detected between data and type \nDATA: #{data} \nTYPE:#{type} " unless data[:args].size == type[:args].size

          (data[:args]).zip(type[:args]).map do |data_n, type_n|
            TezosClient::Tools::ConvertToHash::Base.new(
              data: data_n,
              type: type_n
            ).value
          end.reduce({}, &:merge)
        end
      end
    end
  end
end