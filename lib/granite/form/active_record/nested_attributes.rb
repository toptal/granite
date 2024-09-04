module Granite
  module Form
    module ActiveRecord
      module NestedAttributes
        extend ActiveSupport::Concern

        def accepts_nested_attributes_for(*attr_names)
          options = attr_names.extract_options!
          granite_associations, active_record_association = attr_names.partition do |association_name|
            reflect_on_association(association_name).is_a?(Granite::Form::Model::Associations::Reflections::Base)
          end

          Granite::Form::Model::Associations::NestedAttributes::NestedAttributesMethods
            .accepts_nested_attributes_for(self, *granite_associations, options.dup)
          super(*active_record_association, options.dup)
        end
      end
    end
  end
end
