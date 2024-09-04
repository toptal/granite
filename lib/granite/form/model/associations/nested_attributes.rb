module Granite
  module Form
    module Model
      module Associations
        module NestedAttributes
          extend ActiveSupport::Concern

          DESTROY_ATTRIBUTE = '_destroy'.freeze

          included do
            class_attribute :nested_attributes_options, instance_writer: false
            self.nested_attributes_options = {}

            extend NestedAttributesMethodsExtension
            prepend PrependMethods
          end

          module PrependMethods
            def assign_attributes(attrs)
              if self.class.nested_attributes_options.present?
                attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
                attrs = attrs.stringify_keys

                nested_attrs = self.class.nested_attributes_options.keys
                                   .each_with_object({}) do |association_name, result|
                  name = "#{association_name}_attributes"
                  result[name] = attrs.delete(name) if attrs.key?(name)
                end

                super(attrs.merge!(nested_attrs))
              else
                super(attrs)
              end
            end

            alias attributes= assign_attributes
          end

          class NestedAttributesMethods # rubocop:disable Metrics/ClassLength
            REJECT_ALL_BLANK_PROC = proc { |attributes|
              attributes.all? do |key, value|
                key == DESTROY_ATTRIBUTE || value.blank?
              end
            }

            def self.accepts_nested_attributes_for(klass, *attr_names)
              options = { allow_destroy: false, update_only: false }
              options.update(attr_names.extract_options!)
              options.assert_valid_keys(:allow_destroy, :reject_if, :limit, :update_only)
              options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

              NestedAttributesMethodsExtension.ensure_extended!(klass)

              attr_names.each do |association_name|
                reflection = klass.reflect_on_association(association_name)
                unless reflection
                  raise ArgumentError,
                        "No association found for name `#{association_name}'. Has it been defined yet?"
                end

                klass.nested_attributes_options =
                  klass
                  .nested_attributes_options
                  .merge(association_name.to_sym => options)

                should_validate_nested = klass.respond_to?(:validates_nested) &&
                                         !klass.validates_nested?(association_name)
                klass.validates_nested(association_name) if should_validate_nested

                type = (reflection.collection? ? :collection : :one_to_one)
                klass.nested_attributes_methods_module.class_eval <<-METHOD, __FILE__, __LINE__ + 1
                def #{association_name}_attributes=(attributes)
                  Granite::Form::Model::Associations::NestedAttributes::NestedAttributesMethods
                    .assign_nested_attributes_for_#{type}_association(self, :#{association_name}, attributes)
                end
                METHOD
              end
            end

            def self.assign_nested_attributes_for_one_to_one_association(object, association_name, attributes)
              options = object.nested_attributes_options[association_name]
              attributes = attributes.with_indifferent_access

              association = object.association(association_name)
              existing_record = association.target
              primary_attribute_name = primary_name_for(association.reflection.klass)
              if existing_record
                primary_attribute = existing_record.attribute(primary_attribute_name)
                if primary_attribute
                  primary_attribute_value = primary_attribute.type_definition
                                                             .prepare(attributes[primary_attribute_name])
                end
              end

              should_assign = !primary_attribute ||
                              options[:update_only] ||
                              existing_record.primary_attribute == primary_attribute_value

              if existing_record && should_assign
                assign_to(existing_record, attributes) unless call_reject_if(object, association_name, attributes)
                association.clear if destroy_flag?(attributes) && options[:allow_destroy]
              elsif attributes[primary_attribute_name].present?
                raise Granite::Form::ObjectNotFound.new(object, association_name, attributes[primary_attribute_name])
              elsif !reject_new_object?(object, association_name, attributes, options)
                assignable_attributes = attributes.except(*unassignable_keys(object))

                if existing_record && !existing_record.persisted?
                  existing_record.assign_attributes(assignable_attributes)
                else
                  association.build(assignable_attributes)
                end
              end
            end

            def self.assign_nested_attributes_for_collection_association(object, association_name, attributes_collection) # rubocop:disable Layout/LineLength,Metrics/MethodLength
              options = object.nested_attributes_options[association_name]

              unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
                raise ArgumentError,
                      "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})" # rubocop:disable Layout/LineLength
              end

              check_record_limit!(options[:limit], attributes_collection)

              association = object.association(association_name)
              primary_attribute_name = primary_name_for(association.reflection.klass)

              unless primary_attribute_name
                raise Granite::Form::UndefinedPrimaryAttribute.new(object.class,
                                                                   association_name)
              end

              if attributes_collection.is_a? Hash
                keys = attributes_collection.keys
                attributes_collection =
                  if keys.include?(primary_attribute_name) || keys.include?(primary_attribute_name.to_sym)
                    [attributes_collection]
                  else
                    attributes_collection.values
                  end
              end

              attributes_collection.each do |attributes|
                attributes = attributes.with_indifferent_access

                if attributes[primary_attribute_name].blank?
                  association.build(attributes.except(*unassignable_keys(object))) unless reject_new_object?(
                    object, association_name, attributes, options
                  )
                else
                  existing_record = association.target.detect do |record|
                    primary_attribute_value = record.attribute(primary_attribute_name)
                                                    .type_definition.prepare(attributes[primary_attribute_name])
                    record.primary_attribute == primary_attribute_value
                  end
                  if existing_record
                    assign_to(existing_record, attributes) unless call_reject_if(object, association_name, attributes)
                    association.target.delete(existing_record) if destroy_flag?(attributes) && options[:allow_destroy]
                  elsif association.reflection.embedded?
                    unless reject_new_object?(object, association_name, attributes, options)
                      association.reflection.klass.with_sanitize(false) do
                        association.build(attributes.except(DESTROY_ATTRIBUTE))
                      end
                    end
                  else
                    raise Granite::Form::ObjectNotFound.new(object, association_name,
                                                            attributes[primary_attribute_name])
                  end
                end
              end
            end

            def self.check_record_limit!(limit, attributes_collection)
              limit = case limit
                      when Symbol
                        send(limit)
                      when Proc
                        limit.call
                      else
                        limit
                      end

              return unless limit && attributes_collection.size > limit

              raise Granite::Form::TooManyObjects.new(limit, attributes_collection.size)
            end

            def self.assign_to(object, attributes)
              object.assign_attributes(attributes.except(*unassignable_keys(object)))
            end

            def self.destroy_flag?(hash)
              Types::Boolean.typecast(hash[DESTROY_ATTRIBUTE])
            end

            def self.reject_new_object?(object, association_name, attributes, options)
              options[:update_only] || destroy_flag?(attributes) || call_reject_if(object, association_name, attributes)
            end

            def self.call_reject_if(object, association_name, attributes)
              case callback = object.nested_attributes_options[association_name][:reject_if]
              when Symbol
                method(callback).arity.zero? ? send(callback) : send(callback, attributes)
              when Proc
                callback.call(attributes)
              end
            end

            def self.unassignable_keys(object)
              [primary_name_for(object.class), DESTROY_ATTRIBUTE].compact
            end

            def self.primary_name_for(klass)
              klass < Granite::Form::Model ? klass.primary_name : 'id'
            end
          end

          module ClassMethods
            def accepts_nested_attributes_for(*attr_names)
              NestedAttributesMethods.accepts_nested_attributes_for self, *attr_names
            end
          end

          module NestedAttributesMethodsExtension
            def self.ensure_extended!(klass)
              return if klass.singleton_class.ancestors.include?(self)

              klass.extend(self)
            end

            def nested_attributes_methods_module
              @nested_attributes_methods_module ||= begin
                mod = const_set(:NestedAttributesMethods, Module.new)
                include(mod)
                mod
              end
            end
          end
        end
      end
    end
  end
end
