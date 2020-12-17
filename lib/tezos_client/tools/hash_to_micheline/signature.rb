# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Signature < Base
        def encode
          raise "#{data} does not seem to be a signature" unless data.starts_with?("edsig")
          { string: data }
        end
      end
    end
  end
end
