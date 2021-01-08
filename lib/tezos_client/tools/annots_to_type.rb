# frozen_string_literal: true

class TezosClient::Tools::AnnotsToType < ActiveInteraction::Base
  # example of typed_annots :
  # {
  #   spending_ref: "string",
  #   remainder_amount: "nat",
  #   expires_at: "timestamp"
  # }
  hash :typed_annots, strip: false

  validate :validate_types

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

  def execute
    return { "prim" => typed_annots.values.first } if typed_annots.size == 1

    { "prim" => "pair", "args" => generate_type_args(ordered_annots) }
  end

  private
    def micheline_type(annot_type, annot)
      if annot_type.to_s.start_with?("optional_")
        {
          "prim" => "option",
          "args" => [{ "prim" => annot_type.to_s.delete_prefix("optional_") }],
          "annots" => ["%#{annot}"]
        }
      else
        {
          "prim" => annot_type,
          "annots" => ["%#{annot}"]
        }
      end
    end

    def generate_type_args(annots)
      annot = annots.pop
      annot_type = typed_annots[annot]

      unless annots.size == 1
        return [
          micheline_type(annot_type, annot),
          {
            "prim" => "pair",
            "args" => generate_type_args(annots)
          }
        ]
      end

      generated_args = [micheline_type(annot_type, annot)]
      annot = annots.pop
      annot_type = typed_annots[annot]
      generated_args.append(micheline_type(annot_type, annot))

      generated_args
    end

    def ordered_annots
      @ordered_annots ||= typed_annots.keys.sort.reverse
    end

    def validate_types
      allowed_types = TYPES_MAPPING.keys
      return if typed_annots.values.map{|type| type.to_s.delete_prefix("optional_").to_sym}.all? { |type| type.in? allowed_types }

      errors.add(:base, "The allowed types are: #{allowed_types.join(', ')}")
    end
end
