# frozen_string_literal: true

module SecurityApp
  ProgramSchema = Dry::Validation.Form do
    configure { config.type_specs = true }

    required(:program_name, Types::StrippedString).filled(:str?)
  end
end
