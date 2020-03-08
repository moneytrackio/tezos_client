# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Key < Base
        include TezosClient::Crypto

        def decode
          if data.key?(:bytes)
            if data[:bytes].start_with?("00")
              encode_tz(:edpk, data[:bytes][2..-1])
            elsif data[:bytes].start_with?("01")
              encode_tz(:sppk, data[:bytes][2..-1])
            elsif data[:bytes].start_with?("02")
              encode_tz(:p2pk, data[:bytes][2..-1])
            else
              data[:bytes]
            end
          else
            data[:string]
          end
        end
      end
    end
  end
end