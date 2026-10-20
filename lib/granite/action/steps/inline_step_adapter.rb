module Granite
  class Action
    module Steps
      # Adapts `inline_step` interface to match that of a step action as needed.
      class InlineStepAdapter
        def initialize(action, block)
          @action = action
          @block = block
        end

        def perform!(**options)
          @action.instance_exec(**options, &@block)
        end

        def assign_attributes(_attributes) end

        def errors
          {}
        end

        def failed_preconditions
          []
        end
      end
    end
  end
end
