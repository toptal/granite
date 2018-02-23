module Granite
  module Routing
    module Mapping
      # Override the `ActionDispatch::Routing::Mapper::Mapping#app` method to
      # be able to mount custom Dispatcher objects. Otherwise, the only way to
      # point a dispatcher to business actions is to mount it as a Rack app
      # but we want to use regular Rails flow.
      def app(*)
        if to.is_a?(Granite::Dispatcher)
          ActionDispatch::Routing::Mapper::Constraints.new(
            to,
            to.constraints,
            ActionDispatch::Routing::Mapper::Constraints::SERVE
          )
        else
          super
        end
      end
    end
  end
end

ActionDispatch::Routing::Mapper::Mapping.prepend Granite::Routing::Mapping
