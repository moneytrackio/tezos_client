# frozen_string_literal: true

class TezosClient
  module Tools
    class ConvertToHash < ActiveInteraction::Base
      class Base
        def initialize(data:, type:)
          @data = data
          @type = type
        end

        attr_accessor :data, :type

        def value
          anonymous? ? decode : { var_name => decode }
        end

        protected
          def decode
            klass.new(
              data: data,
              type: type
            ).decode

          rescue NameError
            raise NotImplementedError, "type '#{type[:prim]}' not implemented"
          end

          def anonymous?
            !(type.key?(:annots) && type[:annots].any?)
          end

          def var_name_annot
            type[:annots].first
          end

          def var_name
            return nil if anonymous?

            "#{var_name_annot[1..-1]}".to_sym
          end

        private
          def klass
            "TezosClient::Tools::ConvertToHash::#{type[:prim].camelize}".constantize
          end
      end
    end
  end
end
