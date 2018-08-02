# frozen_string_literal: true

module MasterfilesApp
  AddressSchema = Dry::Validation.Form do
    configure { config.type_specs = true }

    optional(:id, :int).filled(:int?)
    required(:address_type_id, :int).filled(:int?)
    required(:address_line_1, Types::StrippedString).filled(:str?)
    required(:address_line_2, Types::StrippedString).maybe(:str?)
    required(:address_line_3, Types::StrippedString).maybe(:str?)
    required(:city, Types::StrippedString).maybe(:str?)
    required(:postal_code, Types::StrippedString).maybe(:str?)
    required(:country, Types::StrippedString).maybe(:str?)
    required(:active, :bool).maybe(:bool?)
  end
end
