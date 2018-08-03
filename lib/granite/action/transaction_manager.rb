module Granite
  class Action
    class Rollback < defined?(ActiveRecord) ? ActiveRecord::Rollback : StandardError
    end

    module TransactionManager
      class << self
        # Runs a block in a transaction
        # It will open a new transaction or append a block to the current one if it exists
        #
        # @param [Object] trigger_callbacks_for - object which will receive `run_callbacks(:commit)` after transaction commited
        # @return [Object] result of a block
        def transaction(trigger_callbacks_for: nil, &block)
          (callback_listeners << trigger_callbacks_for) if trigger_callbacks_for

          if in_a_transaction?
            yield
          else
            wrap_in_transaction_with_callbacks(&block)
          end
        end

        private

        IN_A_TRANSACTION_KEY = :granite_transaction_manager_in_a_transaction
        CALLBACK_LISTENERS_KEY = :granite_transaction_manager_callback_listeners

        def callback_listeners
          Thread.current[CALLBACK_LISTENERS_KEY] ||= []
        end

        def in_a_transaction?
          !!(Thread.current[IN_A_TRANSACTION_KEY])
        end

        def in_a_transaction=(value)
          Thread.current[IN_A_TRANSACTION_KEY] = value
        end

        def wrap_in_transaction_with_callbacks(&block)
          self.in_a_transaction = true

          result = wrap_in_transaction(&block) || false

          trigger_callbacks if result

          result
        ensure
          callback_listeners.clear
          self.in_a_transaction = nil
        end

        def wrap_in_transaction(&block)
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.transaction(&block)
          else
            begin
              yield
            rescue Granite::Action::Rollback
              false
            end
          end
        end

        def trigger_callbacks
          collected_errors = []

          callback_listeners.reverse.each do |listener|
            begin
              listener.run_callbacks :commit
            rescue StandardError => e
              collected_errors << e
            end
          end

          if collected_errors.any?
            collected_errors[1..-1].each do |error|
              ActiveData.config.logger.error "Unhandled error in callback: #{error.inspect}\n#{error.backtrace.join("\n")}"
            end
            fail collected_errors.first
          end
        end
      end
    end
  end
end
