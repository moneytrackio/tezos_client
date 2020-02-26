# frozen_string_literal: true

class TezosClient::Tools::ConvertToHash < ActiveInteraction::Base
  interface :data
  interface :type

  def execute
    case type[:prim]
    when "pair"
      pair_type(data: data, type: type)
    when "list"
      list_type(data: data, type: type)
    when "int"
      int_type(data: data, type: type)
    when "nat"
      int_type(data: data, type: type)
    when "key"
      key_type(data: data, type: type)
    when "timestamp"
      timestamp_type(data: data, type: type)
    when "string"
      string_type(data: data, type: type)
    when "address"
      address_type(data: data, type: type)
    else
      raise "type '#{type[:prim]}' not implemented"
    end
  end

  private
    def pair_type(data:, type:)
      raise "Not a 'Pair' type" unless data[:prim] == "Pair"
      raise "Difference detected between data and type \nDATA: #{data} \nTYPE:#{type} " unless data[:args].size == type[:args].size

      result = {}
      data[:args].size.times do |iter|
        result.merge!(
          compose(
            TezosClient::Tools::ConvertToHash,
            data: data[:args][iter],
            type: type[:args][iter]
          )
        )
      end
      result
    end

    def list_type(data:, type:)
      value = convert_list_element(data: data, element_type: type[:args].first)
      decorate_value(value: value, type: type)
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

    def int_type(data:, type:)
      value = data[:int].to_i
      decorate_value(value: value, type: type)
    end

    def key_type(data:, type:)
      value = data[:bytes] || data[:string]
      decorate_value(value: value, type: type)
    end

    def timestamp_type(data:, type:)
      value = Time.zone.at(data[:int].to_i)
      decorate_value(value: value, type: type)
    end

    def string_type(data:, type:)
      value = data[:string]
      decorate_value(value: value, type: type)
    end

    def address_type(data:, type:)
      value = data[:bytes] || data[:string]
      decorate_value(value: value, type: type)
    end

    def decorate_value(value:, type:)
      anonymous?(type) ? value : { var_name(type) => value }
    end

    def anonymous?(type)
      !type.key?(:annots)
    end

    def var_name(type)
      return nil if anonymous?(type)

      "#{type[:annots].first[1..-1]}".to_sym
    end
end
