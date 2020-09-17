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

  def execute
    return { "prim" => typed_annots.values.first } if typed_annots.size == 1

    { "prim" => "pair", "args" => generate_type_args(ordered_annots) }
  end

  private
    def generate_type_args(annots)
      annot = annots.pop
      annot_type = typed_annots[annot]

      unless annots.size == 1
        return [
          {
            "prim" => annot_type,
            "annots" => ["%#{annot}"]
          },
          {
            "prim" => "pair",
            "args" => generate_type_args(annots)
          }
        ]
      end

      generated_args = [{ "prim" => annot_type, "annots" => ["%#{annot}"] }]
      annot = annots.pop
      annot_type = typed_annots[annot]
      generated_args.append({ "prim" => annot_type, "annots" => ["%#{annot}"] })

      generated_args
    end

    def ordered_annots
      @ordered_annots ||= typed_annots.keys.sort.reverse
    end

    def validate_types
      allowed_types = TezosClient::Tools::HashToMicheline::TYPES_MAPPING.keys
      return if typed_annots.values.map(&:to_sym).all? { |type| type.in? allowed_types }

      errors.add(:base, "The allowed types are: #{allowed_types.join(', ')}")
    end
end
