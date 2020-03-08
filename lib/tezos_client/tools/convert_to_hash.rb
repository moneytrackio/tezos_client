# frozen_string_literal: true

Dir[File.join(__dir__, "convert_to_hash", "*.rb")].each { |file| require file }

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      interface :data
      interface :type

      def execute
        TezosClient::Tools::ConvertToHash::Base.new(data: data, type: type).value
      end

    end
  end
end
