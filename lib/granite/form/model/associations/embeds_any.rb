module Granite
  module Form
    module Model
      module Associations
        class EmbedsAny < Base
          private

          def build_object(attributes)
            reflection.klass.new(attributes)
          end

          def embed_object(object)
            object.instance_variable_set(:@embedder, owner)
          end

          def model_data(model)
            return unless model

            model.association_names.each { |assoc_name| model.association(assoc_name).sync }
            model.attributes
          end
        end
      end
    end
  end
end
