# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class String < Base
        def decode
          data[:string]
        end
      end
    end
  end
end
