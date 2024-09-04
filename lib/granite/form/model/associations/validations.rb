module Granite
  module Form
    module Model
      module Associations
        module Validations
          def valid_ancestry?
            errors.clear
            validate_nested!
            run_validations!
          end

          alias validate_ancestry valid_ancestry?

          def invalid_ancestry?
            !valid_ancestry?
          end

          def validate_ancestry!
            valid_ancestry? || raise_validation_error
          end

          private

          def validate_nested!
            association_names.each do |name|
              association = association(name)
              invalid_block = if association.reflection.klass.method_defined?(:invalid_ansestry?)
                                ->(object) { object.invalid_ansestry? }
                              else
                                ->(object) { object.invalid? }
                              end

              Granite::Form::Model::Validations::NestedValidator
                .validate_nested(self, name, association.target, &invalid_block)
            end
          end
        end
      end
    end
  end
end
