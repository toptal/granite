require 'granite/action/preconditions/base_precondition'

module Granite
  class Action
    module Preconditions
      class ObjectPrecondition < BasePrecondition
        private

        def _execute(context)
          @args.first.new(context).call(**@options.except(:if, :unless))
        end
      end
    end
  end
end
