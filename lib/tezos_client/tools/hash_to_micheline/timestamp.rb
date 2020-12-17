# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Timestamp < Base
        def encode
          raise "timestamp input (#{data}) must be an instance of Time" unless data.is_a? Time
          { int: data.to_i.to_s }
        end
      end
    end
  end
end
