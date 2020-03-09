# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Address < Base
        include TezosClient::Crypto

        def decode
          if data.key?(:bytes)
            if data[:bytes].start_with?("0000")
              encode_tz(:tz1, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("0001")
              encode_tz(:tz2, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("0002")
              encode_tz(:tz3, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("01")
              encode_tz(:KT, data[:bytes][2..-3])
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