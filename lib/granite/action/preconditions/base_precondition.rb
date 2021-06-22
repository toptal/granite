module Granite
  class Action
    module Preconditions
      class BasePrecondition
        def initialize(*args, &block)
          @options = args.extract_options!
          @args = args
          @block = block
        end

        def execute!(context)
          _execute(context) if context.conditions_satisfied?(**@options)
        end

        private

        def _execute(context)
          context.instance_exec(&@block)
        end
      end
    end
  end
end
