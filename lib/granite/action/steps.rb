require 'granite/action/steps/inline_step_adapter'
require 'granite/action/steps/inline_step_definition'
require 'granite/action/steps/step_definition'

module Granite
  class Action
    # Implements steps DSL for Granite actions & other steps.
    module Steps
      extend ActiveSupport::Concern

      included do
        class_attribute :step_definitions
        self.step_definitions = {}
      end

      # Defines `step` and `inline_step` methods.
      module ClassMethods
        # Defines class based step in this action/step. If a block is passed it will be evaluated in the context of
        # `step_class` to further customize the step.
        # @param name [Symbol] name of the inline step, that should describe what this inline step performs.
        #   Can be used to retrieve step instance using `action.step_name`.
        # @param step_class [Class<Granite::Action>] class that will be used to perform this step.
        # @param required [Boolean, :no_nested_preconditions] if set to `true` step will define its preconditions &
        #   validations on parent action and will be called using `perform!`. If set to `:no_nested_preconditions`
        #   step will define its validations on parent action but not preconditions and will be called using
        #   `perform!`. If set to `false` step will not define its preconditions & validations on parent action and
        #   will be called using `try_perform!`.
        # @param options [Hash] any further options will be passed to nested validation & to step definition.
        # @option options [Boolean, Symbol, Proc] :if will only perform/validate step if condition is satisfied
        # @option options [Boolean, Symbol, Proc] :unless will only perform/validate step unless condition is
        #   satisfied
        # @option options [Hash{Symbol=>Boolean, Symbol, Proc}] :attributes additional attributes that will be
        #   evaluated and passed when initializing step
        def step(name, step_class, required: true, **options, &block)
          if block
            step_class = Class.new(step_class, &block)
            const_set(name.to_s.classify, step_class)
          end

          add_step name, StepDefinition.new(step_class, **options, required:)
          return unless required

          validation_options = options.slice(:if, :unless)
          precondition embedded: name, **validation_options unless required == :no_nested_preconditions
          assign_data(**validation_options) { @steps[name].assign_data }
          validates_nested name, **validation_options
        end

        # Defines inline step in this action/step. Any block passed to this method will be evaluated in the context
        # of parent action/step when it's performed making it convenient method to define a block of code that needs
        # to be executed when parent action/step is performed.
        # @param name [Symbol] name of the inline step, that should describe what this inline step performs.
        # @param options (Hash) any further options will be passed to step definition. These can be used to skip a
        #   step completely under certain conditions by passing `if` or `unless` named parameters.
        def inline_step(name, **options, &block)
          add_step name, InlineStepDefinition.new(block, **options)
        end

        private

        def add_step(name, definition)
          self.step_definitions = step_definitions.merge(name => definition)
          define_method(name) { @steps[name] }
        end
      end

      def assign_attributes(attributes)
        if @steps
          @steps.each_value { |step| step.assign_attributes(attributes) }
        else
          @steps = {}
          step_definitions.each { |identifier, definition| @steps[identifier] = definition.to_step(self, attributes) }
        end

        super
      end

      private

      def execute_perform!(*)
        @steps.each do |name, step|
          definition = step_definitions[name]
          step.public_send(definition.perform_with) if conditions_satisfied?(**definition.options)
        end
      end

      def emerge_represented_attributes_errors!
        super

        @steps.each do |step_name, step|
          keys_for_errors(step.errors).each { |attribute| emerge_errors!(step_name, attribute) }
        end
      end

      def keys_for_errors(errors)
        if errors.is_a?(ActiveModel::Errors)
          errors.attribute_names
        else
          errors.keys
        end
      end

      def emerge_errors!(nested_name, attribute)
        key = :"#{nested_name}.#{attribute}"

        errors.where(key).each do |error|
          errors.import(error, attribute:)
        end
        errors.delete(key)
      end
    end
  end
end
