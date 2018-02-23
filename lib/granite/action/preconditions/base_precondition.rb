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
          return if @options[:if] && !context.instance_exec(&@options[:if])
          return if @options[:unless] && context.instance_exec(&@options[:unless])
          _execute(context)
        end

        private

        def _execute(context)
          context.instance_exec(&@block)
        end
      end
    end
  end
end
