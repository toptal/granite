# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Dictionary < HasSubtype
        def prepare(value)
          value = to_hash(value)
          value = value.stringify_keys.slice(*reflection.keys) if reflection.keys.present?
          value.transform_values { |v| subtype_definition.prepare(v) }.with_indifferent_access
        end

        private

        def to_hash(value)
          Hash[value]
        rescue ArgumentError
          {}
        end
      end
    end
  end
end
