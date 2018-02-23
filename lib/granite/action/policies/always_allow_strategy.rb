module Granite
  class Action
    module Policies
      # A Granite policies strategy which allows an action to be performed unconditionally.
      # No defined policies are evaluated.
      class AlwaysAllowStrategy
        def self.allowed?(_action)
          true
        end
      end
    end
  end
end
