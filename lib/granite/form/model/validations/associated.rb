module Granite
  module Form
    module Model
      module Validations
        class AssociatedValidator < ActiveModel::EachValidator
          def validate_each(record, attribute, value)
            invalid_records = Array.wrap(value).reject do |r|
              r.respond_to?(:valid?) && r.valid?(record.validation_context)
            end
            record.errors.add(attribute, :invalid, **options.merge(value: value)) if invalid_records.present?
          end
        end

        module HelperMethods
          def validates_associated(*attr_names)
            validates_with AssociatedValidator, _merge_attributes(attr_names)
          end
        end
      end
    end
  end
end
