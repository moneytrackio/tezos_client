# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Int < Base
        def encode
          { int: data }
        end
      end
    end
  end
end
