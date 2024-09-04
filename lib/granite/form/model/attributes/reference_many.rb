module Granite
  module Form
    module Model
      module Attributes
        class ReferenceMany < ReferenceOne
          def type_casted_value
            variable_cache(:value) do
              read_before_type_cast.map { |id| type_definition.prepare(id) }
            end
          end

          def read_before_type_cast
            variable_cache(:value_before_type_cast) do
              Array.wrap(@value_cache)
            end
          end
        end
      end
    end
  end
end
