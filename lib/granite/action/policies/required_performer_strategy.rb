module Granite
  class Action
    module Policies
      # A Granite policies strategy which requires a performer to be present
      #
      # and at least one defined policy to be evaluated to true
      class RequiredPerformerStrategy < AnyStrategy
        def self.allowed?(action)
          action.performer.present? && super
        end
      end
    end
  end
end
