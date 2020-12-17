# frozen_string_literal: true

class TezosClient
  module Tools
    class HashToMicheline < ActiveInteraction::Base
      class Base
        def initialize(data:, type:)
          @data = data
          @type = type
        end

        attr_accessor :data, :type

        def value
          @data = anonymous? ? @data : @data.fetch(var_name)
          encode
        end

        protected
          def encode
            klass.new(
              data: data,
              type: type
            ).encode

          rescue NameError
            raise
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
            "#{self.class.name.deconstantize}::#{type[:prim].camelize}".constantize
          end
      end
    end
  end
end
