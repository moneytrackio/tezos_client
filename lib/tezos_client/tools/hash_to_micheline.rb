# frozen_string_literal: true

class TezosClient::Tools::HashToMicheline < ActiveInteraction::Base
  # TODO: handle Arrays and Maps
  TYPES_MAPPING = {
    int: :int,
    nat: :int,
    string: :string,
    signature: :string,
    bytes: :bytes,
    timestamp: :int,
    key: :string,
    address: :string
  }.freeze

  string :contract_address, default: nil
  string :entrypoint, default: nil
  # example of params:
  # {
  #   spending_ref: "toto",
  #   expires_at: Time.now
  # }
  hash :params, strip: false
  hash :storage_type, strip: false, default: {}
  interface :blockchain_client, methods: %i[entrypoint entrypoints], default: -> { TezosClient.new }

  # if storage_type is not received, it is fetched from the blockchain using
  # contract_address and entrypoint (that are mandatory in this case)
  validate :storage_type_or_contract_address_presence

  def execute
    return hash_type_to_hash_data(_storage_type.fetch(:prim), params.values.first) if params.size == 1

    { prim: "Pair", args: generate_micheline(_storage_type[:args]) }
  end

  private
    def generate_micheline(remaining_storage_type)
      remaining_storage_type.each_with_object([]) do |h, acc|
        next acc << { prim: "Pair", args: generate_micheline(h[:args]) } if h[:prim] == "pair"

        annot = h[:annots].first.slice(1..-1).to_sym # remove '%'

        if h[:prim] == "option"
          value = params.fetch(annot)
          if value
            acc << {
              "prim": "Some",
              "args": [
                hash_type_to_hash_data(h[:args][0][:prim], params.fetch(annot))
              ]
            }
          else
            acc << {
              "prim": "None"
            }
          end
        else
          acc << hash_type_to_hash_data(h[:prim], params.fetch(annot))
        end
      end
    end

    def convert_type(michelson_type)
      TYPES_MAPPING.fetch(michelson_type.to_sym)
    end

    def hash_type_to_hash_data(michelson_type, value)
      type = convert_type(michelson_type)

      converted_value = case michelson_type.to_sym
                        when :nat, :int
                          value.to_s
                        when :timestamp
                          errors.add(:base, "timestamp input must be an instance of Time") unless value.is_a? Time

                          value.to_i.to_s
                        else
                          value
      end

      { type => converted_value }
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
