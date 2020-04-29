# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Nat < Base
        def decode
          data[:int].to_i
        end
      end
    end
  end
end
