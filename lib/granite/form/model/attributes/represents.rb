module Granite
  module Form
    module Model
      module Attributes
        class Represents < Attribute
          delegate :reader, :reader_before_type_cast, :writer, to: :reflection

          def initialize(*_args)
            super

            set_default_value
            set_default_value_before_type_cast
          end

          def sync
            reference.public_send(writer, read) if reference.respond_to?(writer)
          end

          def changed?
            if reflection.options.key?(:default)
              reference.public_send(reader) != read
            else
              owner.public_send("#{name}_changed?")
            end
          end

          private

          def reference
            owner.__send__(reflection.reference)
          end

          def set_default_value
            return unless reference.respond_to?(reader)

            variable_cache(:value) do
              normalize(type_definition.prepare(defaultize(reference.public_send(reader))))
            end
          end

          def set_default_value_before_type_cast
            return unless reference.respond_to?(reader_before_type_cast)

            variable_cache(:value_before_type_cast) do
              defaultize(reference.public_send(reader_before_type_cast))
            end
          end
        end
      end
    end
  end
end
