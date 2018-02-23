module Granite
  module Routing
    module Declarer
      class << self
        def declare(routing, route, **options)
          routing.match route.path,
                        via: :all,
                        **options,
                        to: dispatcher,
                        as: route.as,
                        granite_action: route.action_path,
                        granite_projector: route.projector_name
        end

        def dispatcher
          @dispatcher ||= Dispatcher.new
        end

        def reset_dispatcher
          dispatcher.reset!
        end
      end
    end
  end
end
