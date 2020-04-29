# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Bytes < Base
        def decode
          data[:bytes] || data[:string]
        end
      end
    end
  end
end
