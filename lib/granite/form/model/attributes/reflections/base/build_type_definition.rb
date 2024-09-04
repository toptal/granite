module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Base
            class BuildTypeDefinition
              attr_reader :owner, :reflection

              delegate :name, to: :reflection

              def initialize(owner, reflection)
                @owner = owner
                @reflection = reflection
              end

              def call
                raise "Type is not specified for `#{name}`" if type.nil?

                type_definition_for(type)
              end

              private

              def type
                reflection.options[:type]
              end

              def type_definition_for(type)
                type = type.to_s.camelize.constantize unless type.is_a?(Module)
                Granite::Form.type_for(type).new(type, reflection, owner)
              end
            end
          end
        end
      end
    end
  end
end
