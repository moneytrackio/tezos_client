# frozen_string_literal: true

class TezosClient::Tools::FindBigMapsInStorage < ActiveInteraction::Base
  hash :storage,
       strip: false
  hash :storage_type,
       strip: false

  def execute
    hash_storage
      .map(&:last)
      .select { |value| value.is_a? TezosClient::BigMap }
      .map(&:to_h)
      .map(&:with_indifferent_access)
  end

  private

  def hash_storage
    compose(
      TezosClient::Tools::ConvertToHash,
      data: storage,
      type: storage_type
    )
  end
end
