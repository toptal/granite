require 'granite/form'
require 'active_record/errors'
require 'active_record/validations'
require 'active_support/callbacks'

require 'granite/action/error'
require 'granite/action/instrumentation'
require 'granite/action/performing'
require 'granite/action/performer'
require 'granite/action/precondition'
require 'granite/action/preconditions'
require 'granite/action/policies'
require 'granite/action/projectors'
require 'granite/action/subject'
require 'granite/action/translations'

module Granite
  class Action # :nodoc:
    class ValidationError < Error # :nodoc:
      delegate :errors, to: :action

      def initialize(action)
        errors = action.errors.full_messages.join(', ')
        super(I18n.t(:"#{action.class.i18n_scope}.errors.messages.action_invalid",
                     action: action.class,
                     errors: errors,
                     default: :'errors.messages.action_invalid'), action)
      end
    end

    # We are using a lot of stacked additional logic for `assign_attributes`
    # At least, represented and nested attributes modules in Granite::Form
    # are having such a method redefiniions. Both are prepended to the
    # Granite action, so we have to prepend our patch as well in order
    # to put it above all other, so it will handle the attributes first.
    module AssignAttributes
      def assign_attributes(attributes)
        attributes = attributes.to_unsafe_hash if attributes.respond_to?(:to_unsafe_hash)
        attributes = attributes.stringify_keys
        attributes = attributes.merge(attributes.delete(model_name.param_key)) if attributes.key?(model_name.param_key)

        super
      end
    end

    include Base
    include Translations
    include Performing
    include Subject
    include Performer
    include Preconditions
    include Policies
    include Projectors
    prepend AssignAttributes
    prepend Instrumentation

    handle_exception ActiveRecord::RecordInvalid do |e|
      merge_errors(e.record.errors)
    end

    handle_exception Granite::Form::ValidationError do |e|
      merge_errors(e.model.errors)
    end

    handle_exception Granite::Action::ValidationError do |e|
      merge_errors(e.action.errors)
    end

    define_model_callbacks :initialize, only: :after

    def initialize(*)
      super
      _run_initialize_callbacks
    end

    if ActiveModel.version < Gem::Version.new('6.1.0')
      def merge_errors(other_errors)
        errors.messages.deep_merge!(other_errors.messages) do |_, this, other|
          (this + other).uniq
        end
      end
    else
      def merge_errors(other_errors)
        other_errors.each do |error|
          errors.import(error) unless errors.messages[error.attribute].include?(error.message)
        end
      end
    end

    # Almost the same as Dirty `#changed?` method, but
    # doesn't check subject reference key
    def attributes_changed?(except: [])
      except = Array.wrap(except).push(self.class.reflect_on_association(:subject).reference_key)
      changed_attributes.except(*except).present?
    end

    # Check if action is allowed to execute by current performer (see {Granite.performer})
    # and satisfy all defined preconditions
    #
    # @return [Boolean] whether action is performable
    def performable?
      @performable = allowed? && satisfy_preconditions? unless instance_variable_defined?(:@performable)
      @performable
    end

    protected

    def raise_validation_error(original_error = nil)
      raise ValidationError, self, original_error&.backtrace
    end
  end
end
