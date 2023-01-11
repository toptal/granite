require 'granite/action/transaction_manager'

module Granite
  class Action
    module Transaction
      extend ActiveSupport::Concern

      included do
        define_model_callbacks :commit, only: :after
        singleton_class.delegate :transaction, to: :'Granite::Action::TransactionManager'
      end

      def run_callbacks(event)
        if event.to_s == 'commit'
          begin
            super event
          rescue *handled_exceptions => e
            handle_exception(e)
          end
        else
          super event
        end
      end

      private

      attr_accessor :in_transaction

      def transaction(&block)
        if in_transaction
          yield
        else
          run_in_transaction(&block)
        end
      end

      def run_in_transaction
        self.in_transaction = true

        TransactionManager.transaction do
          TransactionManager.after_commit(self)
          yield
        end
      ensure
        self.in_transaction = false
      end
    end
  end
end
