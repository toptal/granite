module Granite
  class Action
    module Types
      class Collection
        attr_reader :subtype_definition

        def initialize(subtype_definition)
          @subtype_definition = subtype_definition
        end

        def ensure_type(value)
          if value.respond_to? :transform_values
            value.transform_values { |v| subtype_definition.ensure_type(v) }
          elsif value.respond_to?(:map)
            value.map { |v| subtype_definition.ensure_type(v) }
          end
        end
      end
    end
  end
end
