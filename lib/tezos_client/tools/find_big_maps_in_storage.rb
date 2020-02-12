# frozen_string_literal: true

class TezosClient::Tools::FindBigMapsInStorage < ActiveInteraction::Base
  hash :storage,
       strip: false
  hash :storage_type,
       strip: false

  def execute
    case storage_type[:prim]
    when "pair"
      pair_type(data: storage, type: storage_type)
    when "list"
      list_type(data: storage, type: storage_type)
    when "big_map"
      big_map_type(data: storage, type: storage_type)
    end
  end

  def pair_type(data:, type:)
    raise "Not a 'Pair' type" unless data[:prim] == "Pair"
    raise "Difference detected between data and type \nDATA: #{data} \nTYPE:#{type} " unless data[:args].size == type[:args].size

    (0 .. data[:args].size - 1).map do |iter|
      compose(
        TezosClient::Tools::FindBigMapsInStorage,
        storage: data[:args][iter],
        storage_type: type[:args][iter]
      )
    end.compact.flatten
  end

  def list_type(data:, type:)
    element_type = type[:args].first
    data.map do |elem|
      compose(
        TezosClient::Tools::ConvertToHash,
        data: elem,
        type: element_type
      )
    end
  end

  def big_map_type(data:, type:)
    {
      name: var_name(type),
      id: data[:int],
      type_value: type[:args].second,
      type_key: type[:args].first
    }.with_indifferent_access
  end

  def var_name(type)
    "#{type[:annots].first[1..-1]}".to_sym
  end
end