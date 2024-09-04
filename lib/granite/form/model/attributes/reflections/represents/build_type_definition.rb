module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Represents
            class BuildTypeDefinition < Base::BuildTypeDefinition
              GRANITE_COLLECTION_TYPES = [Granite::Form::Model::Attributes::ReferenceMany].freeze
              TYPES = {
                'ActiveRecord::Enum::EnumType' => String,
                'ActiveRecord::Type::Serialized' => Object
              }.freeze

              def call
                if type.present?
                  super
                else
                  granite_form_type || active_record_type || type_definition_for(Object)
                end
              end

              private

              def reference
                owner.__send__(reflection.reference)
              end

              def granite_form_type
                return nil unless reference.is_a?(Model)

                reference_attribute = reference.attribute(name)
                return nil if reference_attribute.nil?

                type_definition = reference_attribute.type_definition.build_duplicate(reflection, owner)
                if GRANITE_COLLECTION_TYPES.any? { |klass| reference_attribute.is_a? klass }
                  Types::Collection.new(type_definition)
                else
                  type_definition
                end
              end

              def active_record_type
                return nil unless reference.respond_to?(:type_for_attribute)

                attribute_type = reference.type_for_attribute(active_model_attribute_name.to_s)

                attribute_type_name = attribute_type.class.to_s
                if TYPES.key?(attribute_type_name)
                  type_definition_for(TYPES[attribute_type_name])
                elsif attribute_type.respond_to?(:subtype)
                  Types::Collection.new(convert_active_model_type_to_definition(attribute_type.subtype))
                else
                  convert_active_model_type_to_definition(attribute_type)
                end
              end

              def active_model_attribute_name
                aliases = reference.class.try(:attribute_aliases) || {}
                aliases.fetch(name.to_s, name)
              end

              def convert_active_model_type_to_definition(attribute_type)
                type = attribute_type.try(:value_class) ||
                       Associations::PersistenceAdapters::ActiveRecord::TYPES[attribute_type.type&.to_sym]
                type_definition_for(type) if type
              end
            end
          end
        end
      end
    end
  end
end
