require 'granite/action/transaction_manager/transactions_stack'

module Granite
  class Action
    class Rollback < defined?(ActiveRecord) ? ActiveRecord::Rollback : StandardError
    end

    module TransactionManager
      class << self
        # Runs a block in a transaction
        # It will open a new transaction or append a block to the current one if it exists
        # @return [Object] result of a block
        def transaction(&block)
          run_in_transaction(&block) || false
        ensure
          finish_root_transaction if transactions_stack.depth.zero?
        end

        # Adds a block or listener object to be executed after finishing the current transaction.
        # Callbacks are reset after each transaction.
        # @param [Object] listener an object which will receive `run_callbacks(:commit)` after transaction committed
        # @param [Proc] block a block which will be called after transaction committed
        def after_commit(listener = nil, &block)
          callback = listener || block

          fail 'Block or object is required to register after_commit hook!' unless callback

          transactions_stack.add_callback callback
        end

        private

        TRANSACTIONS_STACK_KEY = :granite_transaction_manager_transactions_stack

        def transactions_stack
          Thread.current[TRANSACTIONS_STACK_KEY] ||= TransactionsStack.new
        end

        def transactions_stack=(value)
          Thread.current[TRANSACTIONS_STACK_KEY] = value
        end

        def run_in_transaction(&block)
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.transaction(requires_new: true) do
              transactions_stack.transaction(&block)
            end
          else
            transactions_stack.transaction(&block)
          end
        end

        def finish_root_transaction
          callbacks = transactions_stack.callbacks

          self.transactions_stack = nil

          trigger_after_commit_callbacks(callbacks)
        end

        def trigger_after_commit_callbacks(callbacks)
          collected_errors = []

          callbacks.reverse_each do |callback|
            callback.respond_to?(:_run_commit_callbacks) ? callback._run_commit_callbacks : callback.call
          rescue StandardError => e
            collected_errors << e
          end

          return unless collected_errors.any?

          log_errors(collected_errors[1..])
          fail collected_errors.first
        end

        def log_errors(errors)
          errors.each do |error|
            Granite::Form.config.logger.error "Unhandled error in callback: #{error.inspect}\n#{error.backtrace.join("\n")}"
          end
        end
      end
    end
  end
end
