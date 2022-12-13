module Granite
  module Represents
    class Attribute < Granite::Form::Model::Attributes::Attribute
      types = {}
      types[ActiveRecord::Enum::EnumType] = String if defined?(ActiveRecord)
      TYPES = types.freeze
      GRANITE_COLLECTION_TYPES = [
        Granite::Form::Model::Attributes::ReferenceMany,
        Granite::Form::Model::Attributes::Collection,
        Granite::Form::Model::Attributes::Dictionary
      ].freeze
      delegate :writer, :reader, :reader_before_type_cast, to: :reflection

      def initialize(*_args)
        super

        set_default_value
        set_default_value_before_type_cast
      end

      def sync
        reference.public_send(writer, read) if reference.respond_to?(writer)
      end

      def type_definition
        @type_definition ||= if reflection.options[:type].present?
                               build_type_definition(reflection.options[:type])
                             else
                               granite_form_type_definition || active_record_type_definition || super
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
          normalize(enumerize(type_definition.ensure_type(defaultize(reference.public_send(reader)))))
        end
      end

      def set_default_value_before_type_cast
        return unless reference.respond_to?(reader_before_type_cast)

        variable_cache(:value_before_type_cast) do
          defaultize(reference.public_send(reader_before_type_cast))
        end
      end

      def granite_form_type_definition
        return nil unless reference.is_a?(Granite::Form::Model)

        reference_attribute = reference.attribute(name)

        return nil if reference_attribute.nil?

        type_definition = build_type_definition(reference_attribute.type)
        if GRANITE_COLLECTION_TYPES.any? { |klass| reference_attribute.is_a? klass }
          Granite::Action::Types::Collection.new(type_definition)
        else
          type_definition
        end
      end

      def active_record_type_definition
        return nil unless reference.respond_to?(:type_for_attribute)

        attribute_type = reference.type_for_attribute(attribute_name.to_s)

        if TYPES.key?(attribute_type.class)
          build_type_definition(TYPES[attribute_type.class])
        elsif attribute_type.respond_to?(:subtype)
          Granite::Action::Types::Collection.new(convert_active_model_type_to_definition(attribute_type.subtype))
        else
          convert_active_model_type_to_definition(attribute_type)
        end
      end

      def attribute_name
        return name if ActiveModel.version >= Gem::Version.new('6.1.0')

        reference.class.attribute_aliases[name.to_s] || name
      end

      def convert_active_model_type_to_definition(attribute_type)
        type = attribute_type.try(:value_class) ||
          Form::Model::Associations::PersistenceAdapters::ActiveRecord::TYPES[attribute_type.type&.to_sym]
        build_type_definition(type) if type
      end
    end
  end
end
