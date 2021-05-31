# frozen_string_literal: true

class TezosClient
  class BigMap < Struct.new(:name, :id, :value_type, :key_type); end

  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class BigMap < Base
        def decode
          if data.is_a? Hash
            ::TezosClient::BigMap.new(
              var_name,
              data[:int],
              type[:args].second,
              type[:args].first
            )
          else
            TezosClient::Tools::ConvertToHash::Map.new(
              data: data,
              type: type
            ).value[var_name]
          end
        end
      end
    end
  end
end
