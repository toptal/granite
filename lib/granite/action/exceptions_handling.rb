module Granite
  class Action
    module ExceptionsHandling
      extend ActiveSupport::Concern

      included do
        class_attribute :_exception_handlers, instance_writer: false
        self._exception_handlers = {}

        protected :_exception_handlers # rubocop:disable Style/AccessModifierDeclarations
      end

      module ClassMethods
        # Register default handler for exceptions thrown inside execute_perform! and after_commit methods.
        # @param klass Exception class, could be parent class too [Class]
        # @param block [Block<Exception>] with default behavior for handling specified
        #   type exceptions. First block argument is raised exception instance.
        #
        # @return [Hash<Class, Proc>] Registered handlers
        def handle_exception(klass, &block)
          self._exception_handlers = _exception_handlers.merge(klass => block)
        end
      end

      private

      def handled_exceptions
        _exception_handlers.keys
      end

      def handle_exception(e)
        klass = e.class.ancestors.detect do |ancestor|
          ancestor <= Exception && _exception_handlers[ancestor]
        end
        instance_exec(e, &_exception_handlers[klass]) if klass
      end
    end
  end
end
