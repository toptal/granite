# frozen_string_literal: true

module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Dictionary
            class BuildTypeDefinition < Base::BuildTypeDefinition
              def call
                Types::Dictionary.new(super)
              end
            end
          end
        end
      end
    end
  end
end
