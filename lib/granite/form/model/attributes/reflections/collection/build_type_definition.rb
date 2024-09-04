# frozen_string_literal: true

module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Collection
            class BuildTypeDefinition < Base::BuildTypeDefinition
              def call
                Types::Collection.new(super)
              end
            end
          end
        end
      end
    end
  end
end
