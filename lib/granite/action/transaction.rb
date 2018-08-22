module Granite
  class Action
    class Rollback < defined?(ActiveRecord) ? ActiveRecord::Rollback : StandardError
    end

    module Transaction
      extend ActiveSupport::Concern

      private

      def transactional(&block)
        if transactional?
          yield
        else
          @_transactional = true
          result = transaction(&block) || false
          @_transactional = nil
          result
        end
      end

      def transactional?
        # Fuck the police!
        !(!@_transactional)
      end

      def transaction(&block)
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
    end
  end
end
