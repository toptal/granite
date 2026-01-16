require 'granite/action/preconditions/base_precondition'

module Granite
  class Action
    module Preconditions
      # Checks related business actions for precondition errors and adds them to current action.
      #
      #   memoize def child_action
      #     ...
      #   end
      #   precondition embedded: :child_action
      #
      #   memoize def child_action
      #     ...
      #   end
      #   memoize def child_actions
      #     ...
      #   end
      #   precondition embedded: [:child_action, :child_actions]
      #
      class EmbeddedPrecondition < BasePrecondition
        private

        def _execute(context)
          associations = Array.wrap(@args.first)
          associations.each do |name|
            actions = Array.wrap(context.__send__(name))
            actions.each do |action|
              decline_action(context, action)
            end
          end
        end

        def decline_action(context, action)
          return if action.satisfy_preconditions?

          action.errors.where(:base).each { context.errors.import(_1) }
          action.failed_preconditions.each { context.failed_preconditions << _1 }
        end
      end
    end
  end
end
