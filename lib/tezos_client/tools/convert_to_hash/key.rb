# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Key < Base
        include TezosClient::Crypto

        def decode
          if tmp_data.start_with?("00")
            encode_tz(:edpk, tmp_data[2..-1])
          elsif tmp_data.start_with?("01")
            encode_tz(:sppk, tmp_data[2..-1])
          elsif tmp_data.start_with?("02")
            encode_tz(:p2pk, tmp_data[2..-1])
          else
            tmp_data
          end
        end

        def tmp_data
          @tmp_data ||= data[:bytes] || data[:string]
        end
      end
    end
  end
end
