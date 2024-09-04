module Granite
  module Form
    module Types
      class HasSubtype
        attr_reader :subtype_definition

        delegate :reflection, :owner, :type, :name, :enum, to: :subtype_definition

        def initialize(subtype_definition)
          @subtype_definition = subtype_definition
        end

        def build_duplicate(*args)
          self.class.new(subtype_definition.build_duplicate(*args))
        end
      end
    end
  end
end
