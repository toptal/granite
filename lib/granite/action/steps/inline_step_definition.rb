module Granite
  class Action
    module Steps
      # Step definition for inline steps. Can be converted to step instance using {#to_step} method.
      class InlineStepDefinition
        attr_reader :options

        def initialize(block, **options)
          @block = block
          @options = options
        end

        def to_step(action, _attributes)
          InlineStepAdapter.new(action, @block)
        end

        def perform_with
          :perform!
        end
      end
    end
  end
end
