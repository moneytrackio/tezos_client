# frozen_string_literal: true

class TezosClient
  class BigMap < Struct.new(:name, :id, :value_type, :key_type); end

  module Tools
    class ConvertToHash < ActiveInteraction::Base
      include TezosClient::Crypto

      interface :data
      interface :type

      def execute
        decorated_value
      end

      private
        def value
          case type[:prim]
          when "pair"
            pair_type
          when "list"
            list_type
          when "int"
            int_type
          when "nat"
            int_type
          when "key"
            key_type
          when "timestamp"
            timestamp_type
          when "string"
            string_type
          when "address"
            address_type
          when "bytes"
            bytes_type
          when "signature"
            signature_type
          when "big_map"
            big_map_type
          else
            raise "type '#{type[:prim]}' not implemented"
          end
        end

        def pair_type
          raise "Not a 'Pair' type" unless data[:prim] == "Pair"
          raise "Difference detected between data and type \nDATA: #{data} \nTYPE:#{type} " unless data[:args].size == type[:args].size

          (data[:args]).zip(type[:args]).map do |data_n, type_n|
            compose(
              TezosClient::Tools::ConvertToHash,
              data: data_n,
              type: type_n
            )
          end.reduce({}, &:merge)
        end

        def list_type
          convert_list_element(data: data, element_type: type[:args].first)
        end

        def convert_list_element(data:, element_type:)
          data.map do |elem|
            compose(
              TezosClient::Tools::ConvertToHash,
              data: elem,
              type: element_type
            )
          end
        end

        def int_type
          data[:int].to_i
        end

        def big_map_type
          BigMap.new(
            var_name,
            data[:int],
            type[:args].second,
            type[:args].first
          )
        end

        def key_type
          if data.key?(:bytes)
            if data[:bytes].start_with?("00")
              encode_tz(:edpk, data[:bytes][2..-1])
            elsif data[:bytes].start_with?("01")
              encode_tz(:sppk, data[:bytes][2..-1])
            elsif data[:bytes].start_with?("02")
              encode_tz(:p2pk, data[:bytes][2..-1])
            else
              data[:bytes]
            end
          else
            data[:string]
          end
        end

        def timestamp_type
          Time.zone.at(data[:int].to_i)
        end

        def string_type
          data[:string]
        end

        def address_type
          if data.key?(:bytes)
            if data[:bytes].start_with?("0000")
              encode_tz(:tz1, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("0001")
              encode_tz(:tz2, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("0002")
              encode_tz(:tz3, data[:bytes][4..-1])
            elsif data[:bytes].start_with?("01")
              encode_tz(:KT, data[:bytes][2..-3])
            else
              data[:bytes]
            end
          else
            data[:string]
          end
        end

        def bytes_type
          data[:bytes] || data[:string]
        end

        def signature_type
          if data.key?(:bytes)
            encode_tz(:edsig, data[:bytes])
          else
            data[:string]
          end
        end

        def decorated_value
          anonymous? ? value : { var_name => value }
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
    end
  end
end
