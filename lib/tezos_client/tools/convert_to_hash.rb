# frozen_string_literal: true

class TezosClient::Tools::ConvertToHash < ActiveInteraction::Base
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

  def key_type
    data[:bytes] || data[:string]
  end

  def timestamp_type
    Time.zone.at(data[:int].to_i)
  end

  def string_type
    data[:string]
  end

  def address_type
    data[:bytes] || data[:string]
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
