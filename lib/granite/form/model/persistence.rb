module Granite
  module Form
    module Model
      module Persistence
        extend ActiveSupport::Concern

        module ClassMethods
          def instantiate(data)
            data = data.stringify_keys
            instance = allocate

            instance.instance_variable_set(:@initial_attributes, data.slice(*attribute_names))
            instance.send(:mark_persisted!)

            instance
          end

          def instantiate_collection(data)
            collection = Array.wrap(data).map { |attrs| instantiate attrs }
            collection = scope(collection, true) if respond_to?(:scope)
            collection
          end
        end

        def persisted?
          !!@persisted
        end

        def marked_for_destruction?
          false
        end

        private

        def mark_persisted!
          @persisted = true
        end
      end
    end
  end
end
