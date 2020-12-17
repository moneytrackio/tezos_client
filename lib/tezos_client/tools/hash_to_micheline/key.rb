# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Key < Base
        def encode
          raise "#{data} #{data.class} Not a 'String' type" unless data.is_a? ::String
          { string: data }
        end
      end
    end
  end
end
