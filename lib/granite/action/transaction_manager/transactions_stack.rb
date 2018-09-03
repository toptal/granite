module Granite
  class Action
    module TransactionManager
      # A class to manage transaction callbacks stack.
      class TransactionsStack
        attr_reader :depth

        def initialize
          @callbacks = []
          @depth = 0
        end

        def transaction
          start_new!
          result = yield
          finish_current!
          result
        rescue StandardError, ScriptError
          rollback_current!
          raise
        end

        def add_callback(callback)
          fail 'Start a transaction before you add callbacks on it' if depth.zero?

          @callbacks.last << callback
        end

        def callbacks
          @callbacks.flatten
        end

        private

        def start_new!
          @depth += 1
          @callbacks << []
        end

        def finish_current!
          finish_current(true)
        end

        def rollback_current!
          finish_current(false)
        end

        def finish_current(result)
          fail ArgumentError, 'No current transaction' if @depth.zero?

          @depth -= 1

          if result
            current = @callbacks.pop
            previous = @callbacks.pop
            @callbacks << [previous, current].flatten.compact
          else
            @callbacks.pop
          end
        end

      end
    end
  end
end
