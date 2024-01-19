require 'granite/action/exceptions_handling'
require 'granite/action/transaction'
require 'granite/action/error'

module Granite
  class Action
    # Performing module used for defining perform procedure and error
    # handling. Perform procedure is defined as block, which is
    # executed in action instance context so all attributes are
    # available there. Actions by default are performed in silent way
    # (no validation exception raised), to raise exceptions, call bang
    # method {Granite::Action::Performing#perform!}
    #
    # Defined exceptions handlers are also executed in action
    # instance context, but additionally get raised exception as
    # parameter.
    #
    module Performing
      extend ActiveSupport::Concern

      include ExceptionsHandling
      include Transaction

      included do
        define_callbacks :execute_perform
      end

      module ClassMethods
        def perform(*)
          fail 'Perform block declaration was removed! Please declare `private def execute_perform!(*)` method'
        end
      end

      # Check preconditions and validations for action and associated objects, then
      # in case of valid action run defined procedure. Procedure is wrapped with
      # database transaction. Returns the result of execute_perform! method execution
      # or true if method execution returned false or nil
      #
      # @param context [Symbol] can be optionally provided to define which
      #   validations to test against (the context is defined on validations
      #   using `:on`)
      # @return [Object] result of execute_perform! method execution or false in case of errors
      def perform(context: nil, **options)
        transaction do
          valid?(context) && perform_action(**options)
        end
      end

      # Check precondition and validations for action and associated objects, then
      # raise exception in case of validation errors. In other case run defined procedure.
      # Procedure is wraped with database transaction. After procedure execution check for
      # errors, and raise exception if any. Returns the result of execute_perform! method execution
      # or true if block execution returned false or nil
      #
      # @param context [Symbol] can be optionally provided to define which
      #   validations to test against (the context is defined on validations
      #   using `:on`)
      # @return [Object] result of execute_perform! method execution
      # @raise [Granite::Action::ValidationError] Action or associated objects are invalid
      # @raise [NotImplementedError] execute_perform! method was not defined yet
      def perform!(context: nil, **options)
        transaction do
          validate!(context)
          perform_action!(**options)
        end
      end

      # Performs action if preconditions are satisfied.
      #
      # @param context [Symbol] can be optionally provided to define which
      #   validations to test against (the context is defined on validations
      #   using `:on`)
      # @return [Object] result of execute_perform! method execution
      # @raise [Granite::Action::ValidationError] Action or associated objects are invalid
      # @raise [NotImplementedError] execute_perform! method was not defined yet
      def try_perform!(context: nil, **options)
        return unless satisfy_preconditions?

        transaction do
          validate!(context)
          perform_action!(**options)
        end
      end

      # Checks if action was successfully performed or not
      #
      # @return [Boolean] whether action was successfully performed or not
      def performed?
        @_action_performed.present?
      end

      private

      def perform_action(raise_errors: false, **options)
        result = run_callbacks(:execute_perform) do
          apply_association_changes!
          execute_perform!(**options)
        end
        @_action_performed = true
        result || true
      rescue *handled_exceptions => e
        handle_exception(e)
        raise_validation_error(e) if raise_errors
        raise Rollback
      end

      def perform_action!(**options)
        perform_action(raise_errors: true, **options)
      end

      def execute_perform!(**_options)
        fail NotImplementedError, "BA perform body MUST be defined for #{self}"
      end
    end
  end
end
