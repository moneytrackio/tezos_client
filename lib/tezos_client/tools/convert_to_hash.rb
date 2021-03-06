# frozen_string_literal: true

require_relative "convert_to_hash/base"

Dir[File.join(__dir__, "convert_to_hash", "*.rb")].each { |file| require file }

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      interface :data, methods: []
      interface :type, methods: []

      def execute
        TezosClient::Tools::ConvertToHash::Base.new(data: data, type: type).value
      end
    end
  end
end
