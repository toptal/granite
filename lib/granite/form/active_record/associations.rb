module Granite
  module Form
    module ActiveRecord
      module Associations
        READER = lambda do |ref, object|
          value = object.read_attribute(ref.name)
          if value.present?
            value.is_a?(String) ? JSON.parse(value) : value
          end
        end

        WRITER = lambda do |ref, object, value|
          object.send(:write_attribute, ref.name, value ? value.to_json : nil)
        end

        module Reflections
          class EmbedsOne < Granite::Form::Model::Associations::Reflections::EmbedsOne
            def is_a?(klass)
              super || klass == ::ActiveRecord::Reflection::AssociationReflection
            end
          end

          class EmbedsMany < Granite::Form::Model::Associations::Reflections::EmbedsMany
            def is_a?(klass)
              super || klass == ::ActiveRecord::Reflection::AssociationReflection
            end
          end
        end

        extend ActiveSupport::Concern

        included do
          { embeds_many: Reflections::EmbedsMany,
            embeds_one: Reflections::EmbedsOne }.each do |(method, reflection_class)|
            define_singleton_method method do |name, options = {}, &block|
              reflection = reflection_class.build(self, self, name,
                                                  options.reverse_merge(read: READER, write: WRITER),
                                                  &block)
              if ::ActiveRecord::Reflection.respond_to? :add_reflection
                ::ActiveRecord::Reflection.add_reflection self, reflection.name, reflection
              else
                self.reflections = reflections.merge(reflection.name => reflection)
              end

              callback_name = :"update_#{reflection.name}_association"
              before_save callback_name
              class_eval <<-METHOD, __FILE__, __LINE__ + 1
              def #{callback_name}
                association(:#{reflection.name}).sync
              end
              METHOD
            end
          end
        end
      end
    end
  end
end
