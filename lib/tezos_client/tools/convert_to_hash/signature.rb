# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Signature < Base
        include TezosClient::Crypto

        def decode
          if data.key?(:bytes)
            encode_tz(:edsig, data[:bytes])
          else
            data[:string]
          end
        end
      end
    end
  end
end
