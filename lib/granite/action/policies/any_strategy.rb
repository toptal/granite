module Granite
  class Action
    module Policies
      # Granite BA policy which allows action to be performed if at least one defined policy evaluates to true
      class AnyStrategy
        def self.allowed?(action)
          action._policies.any? { |policy| action.instance_exec(action.performer, &policy) }
        end
      end
    end
  end
end
