module Granite
  module Represents
    class Attribute < ActiveData::Model::Attributes::Attribute
      delegate :writer, :reader, :reader_before_type_cast, to: :reflection

      def initialize(*_args)
        super

        set_default_value
        set_default_value_before_type_cast
      end

      def sync
        reference.public_send(writer, read) if reference.respond_to?(writer)
      end

      def typecast(value)
        return value if value.class == type

        typecaster.call(value, self) unless value.nil?
      end

      def type
        return reflection.options[:type] if reflection.options[:type].present?

        active_data_type || type_from_type_for_attribute || super
      end

      def typecaster
        @typecaster ||= begin
                          type_class = type.instance_of?(Class) ? type : type.class
                          @typecaster = ActiveData.typecaster(type_class.ancestors.grep(Class))
                        end
      end

      def changed?
        if reflection.options[:default].present?
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
          normalize(enumerize(typecast(defaultize(reference.public_send(reader)))))
        end
      end

      def set_default_value_before_type_cast
        return unless reference.respond_to?(reader_before_type_cast)

        variable_cache(:value_before_type_cast) do
          defaultize(reference.public_send(reader_before_type_cast))
        end
      end

      def active_data_type
        return nil unless reference.is_a?(ActiveData::Model)

        reference_attribute = reference.attribute(name)

        return nil if reference_attribute.nil?

        return Granite::Action::Types::Collection.new(reference_attribute.type) if [
          ActiveData::Model::Attributes::ReferenceMany,
          ActiveData::Model::Attributes::Collection,
          ActiveData::Model::Attributes::Dictionary
        ].any? { |klass| reference_attribute.is_a? klass }

        reference_attribute.type # TODO: create `type_for_attribute` method inside of ActiveData
      end

      def type_from_type_for_attribute
        return nil unless reference.respond_to?(:type_for_attribute)

        attribute_type = reference.type_for_attribute(name.to_s)

        return Granite::Action::Types::Collection.new(convert_type_to_value_class(attribute_type.subtype)) if attribute_type.respond_to?(:subtype)

        convert_type_to_value_class(attribute_type)
      end

      def convert_type_to_value_class(attribute_type)
        return attribute_type.value_class if attribute_type.respond_to?(:value_class)

        ActiveData::Model::Associations::PersistenceAdapters::ActiveRecord::TYPES[attribute_type.type&.to_sym]
      end
    end
  end
end
