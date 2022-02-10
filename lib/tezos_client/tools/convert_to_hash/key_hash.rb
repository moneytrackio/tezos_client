# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class KeyHash < Base
        def decode
          Address.new(data: data, type: type).decode
        end
      end
    end
  end
end
