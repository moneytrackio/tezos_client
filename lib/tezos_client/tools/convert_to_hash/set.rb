# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Set < Base
        def decode
          List.new(data: data, type: type).decode.to_set
        end
      end
    end
  end
end
