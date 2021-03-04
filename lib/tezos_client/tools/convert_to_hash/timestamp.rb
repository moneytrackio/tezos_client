# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Timestamp < Base
        def decode
          if data.key? :int
            Time.zone.at(data[:int].to_i)
          elsif data.key? :string
            return Time.zone.at(data[:string].to_i) if data[:string].match?(/\A\d+\z/)

            Time.zone.parse(data[:string])
          else
            raise "Can not convert timestamp: #{data}"
          end
        end
      end
    end
  end
end
