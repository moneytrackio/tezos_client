# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Timestamp < Base
        def decode
          Time.zone.at(data[:int].to_i)
        end
      end
    end
  end
end
