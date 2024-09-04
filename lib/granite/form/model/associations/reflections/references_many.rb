require 'granite/form/model/attributes/reflections/reference_many'
require 'granite/form/model/attributes/reference_many'

module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class ReferencesMany < ReferencesAny
            def self.build(target, generated_methods, name, *args, &block)
              reflection = super

              target.add_attribute(
                Granite::Form::Model::Attributes::Reflections::ReferenceMany,
                reflection.reference_key,
                type: reflection.persistence_adapter.primary_key_type,
                association: name
              )

              reflection
            end

            def reference_key
              @reference_key ||= options[:reference_key].presence.try(:to_sym) ||
                                 :"#{name.to_s.singularize}_#{primary_key.to_s.pluralize}"
            end
          end
        end
      end
    end
  end
end
