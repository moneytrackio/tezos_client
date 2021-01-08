# frozen_string_literal: true

require_relative "hash_to_micheline/base"

Dir[File.join(__dir__, "hash_to_micheline", "*.rb")].each { |file| require file }


class TezosClient::Tools::HashToMicheline < ActiveInteraction::Base
  string :contract_address, default: nil
  string :entrypoint, default: nil
  # example of params:
  # {
  #   spending_ref: "toto",
  #   expires_at: Time.now
  # }
  interface :params
  hash :storage_type, strip: false, default: {}
  interface :blockchain_client, methods: %i[entrypoint entrypoints select_entrypoint], default: -> { TezosClient.new }

  # if storage_type is not received, it is fetched from the blockchain using
  # contract_address and entrypoint (that are mandatory in this case)
  validate :storage_type_or_contract_address_presence

  def execute
    TezosClient::Tools::HashToMicheline::Base.new(data: _params, type: _storage_type).value
  end

  private
    def _params
      if params.respond_to?(:keys) && params.keys.size == 1
        params.values.first
      else
        params
      end
    end

    def _entrypoint
      @_entrypoint ||= blockchain_client.select_entrypoint(
        contract_address: contract_address,
        entrypoint: entrypoint
      )
    end

    def _storage_type
      (storage_type.presence || blockchain_client.entrypoint(contract_address, _entrypoint)).deep_symbolize_keys
    end

    def storage_type_or_contract_address_presence
      return if storage_type.present? ^ (contract_address.present?)

      errors.add(:base,
                 "You should provide the contract_address and the entrypoint only if storage_type is not provided")
    end
end
