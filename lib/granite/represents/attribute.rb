module Granite
  module Represents
    class Attribute < Granite::Form::Model::Attributes::Attribute
      types = {}
      types[ActiveRecord::Enum::EnumType] = String if defined?(ActiveRecord)
      TYPES = types.freeze
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
        return value if value.class == type # rubocop:disable Style/ClassEqualityComparison

        typecaster.call(value, self) unless value.nil?
      end

      def type
        return reflection.options[:type] if reflection.options[:type].present?

        granite_form_type || type_from_type_for_attribute || super
      end

      def typecaster
        @typecaster ||= begin
          type_class = type.instance_of?(Class) ? type : type.class
          @typecaster = Granite::Form.typecaster(type_class.ancestors.grep(Class))
        end
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
          normalize(enumerize(typecast(defaultize(reference.public_send(reader)))))
        end
      end

      def set_default_value_before_type_cast
        return unless reference.respond_to?(reader_before_type_cast)

        variable_cache(:value_before_type_cast) do
          defaultize(reference.public_send(reader_before_type_cast))
        end
      end

      def granite_form_type
        return nil unless reference.is_a?(Granite::Form::Model)

        reference_attribute = reference.attribute(name)

        return nil if reference_attribute.nil?

        return Granite::Action::Types::Collection.new(reference_attribute.type) if [
          Granite::Form::Model::Attributes::ReferenceMany,
          Granite::Form::Model::Attributes::Collection,
          Granite::Form::Model::Attributes::Dictionary
        ].any? { |klass| reference_attribute.is_a? klass }

        reference_attribute.type # TODO: create `type_for_attribute` method inside of Granite::Form
      end

      def type_from_type_for_attribute
        return nil unless reference.respond_to?(:type_for_attribute)

        attribute_type = reference.type_for_attribute(attribute_name.to_s)

        return TYPES[attribute_type.class] if TYPES.key?(attribute_type.class)
        return Granite::Action::Types::Collection.new(convert_type_to_value_class(attribute_type.subtype)) if attribute_type.respond_to?(:subtype)

        convert_type_to_value_class(attribute_type)
      end

      def attribute_name
        return name if ActiveModel.version >= Gem::Version.new('6.1.0')

        reference.class.attribute_aliases[name.to_s] || name
      end

      def convert_type_to_value_class(attribute_type)
        return attribute_type.value_class if attribute_type.respond_to?(:value_class)

        Granite::Form::Model::Associations::PersistenceAdapters::ActiveRecord::TYPES[attribute_type.type&.to_sym]
      end
    end
  end
end
