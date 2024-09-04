require_relative 'validations/nested'
require_relative 'validations/associated'

module Granite
  module Form
    module Model
      module Validations
        extend ActiveSupport::Concern
        include ActiveModel::Validations

        included do
          extend HelperMethods
          include HelperMethods

          alias_method :validate, :valid?
        end

        class_methods do
          def validates_presence?(attr)
            _validators[attr.to_sym].grep(ActiveModel::Validations::PresenceValidator).present?
          end
        end

        def validate!(context = nil)
          valid?(context) || raise_validation_error
        end

        protected

        def raise_validation_error
          raise Granite::Form::ValidationError, self
        end
      end
    end
  end
end
