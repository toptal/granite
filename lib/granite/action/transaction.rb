require 'granite/action/transaction_manager'

module Granite
  class Action
    module Transaction
      extend ActiveSupport::Concern

      included do
        define_callbacks :commit
      end

      module ClassMethods
        delegate :transaction, to: :'Granite::Action::TransactionManager'

        private

        # Defines a callback which will be triggered right after transaction committed
        # Uses the same arguments as `ActiveSupport::Callbacks.set_callback` except for the first two
        #
        def after_commit(*args, &block)
          set_callback :commit, :after, *args, &block
        end
      end

      def run_callbacks_with_rescue(event)
        run_callbacks event
      rescue *_exception_handlers.keys => e
        handle_exception(e)
      end

      private

      def transaction(&block)
        self.class.transaction(trigger_callbacks_for: self, &block)
      end
    end
  end
end
