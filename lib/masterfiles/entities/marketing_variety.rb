# frozen_string_literal: true

class MarketingVariety < Dry::Struct
  attribute :id, Types::Int
  attribute :marketing_variety_code, Types::String
  attribute :description, Types::String
end