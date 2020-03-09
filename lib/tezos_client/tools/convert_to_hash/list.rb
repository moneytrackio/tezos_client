# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class List < Base
        def decode
          data.map do |elem|
            TezosClient::Tools::ConvertToHash::Base.new(
              data: elem,
              type: elem_type
            ).value
          end
        end

        def elem_type
          type[:args].first
        end
      end
    end
  end
end