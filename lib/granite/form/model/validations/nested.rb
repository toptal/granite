require 'active_model/version'

module Granite
  module Form
    module Model
      module Validations
        class NestedValidator < ActiveModel::EachValidator
          def self.validate_nested(record, name, value)
            if value.is_a?(Enumerable)
              value.each.with_index do |object, i|
                import_errors(object.errors, record.errors, "#{name}.#{i}") if yield object
              end
            elsif value
              import_errors(value.errors, record.errors, name.to_s) if yield value
            end
          end

          if ActiveModel.version >= Gem::Version.new('6.1.0')
            def self.import_errors(from, to, prefix)
              from.each do |error|
                key = "#{prefix}.#{error.attribute}"
                to.import(error, attribute: key) unless to.messages_for(key).include?(error.message)
              end
            end
          else
            # up to 6.0.x
            def self.import_errors(from, to, prefix)
              from.each do |key, message|
                key = "#{prefix}.#{key}"
                to[key] << message
                to[key].uniq!
              end
            end
          end

          def validate_each(record, attribute, value)
            self.class.validate_nested(record, attribute, value) do |object|
              object.invalid? && !(object.respond_to?(:marked_for_destruction?) && object.marked_for_destruction?)
            end
          end
        end

        module HelperMethods
          def validates_nested(*attr_names)
            validates_with NestedValidator, _merge_attributes(attr_names)
          end

          def validates_nested?(attr)
            _validators[attr.to_sym]
              .grep(Granite::Form::Model::Validations::NestedValidator).present?
          end
        end
      end
    end
  end
end
