module Granite
  class Action
    module Instrumentation
      def perform!(*, **)
        instrument_perform(:perform!) { super }
      end

      def perform(*, **)
        instrument_perform(:perform) { super }
      end

      def try_perform!(*, **)
        instrument_perform(:try_perform!) { super }
      end

      private

      def instrument_perform(using, &block)
        ActiveSupport::Notifications.instrument('granite.perform_action', action: self, using: using, &block)
      end
    end
  end
end
