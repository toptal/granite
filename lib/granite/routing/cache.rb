module Granite
  module Routing
    class Cache
      attr_reader :routes

      def initialize(routes)
        @routes = routes
      end

      def [](action, projector)
        projector = projector.to_s
        Array(grouped_routes[action.to_s]).detect do |route|
          route.required_defaults[:granite_projector] == projector
        end
      end

      private

      def grouped_routes
        @grouped_routes ||= routes.group_by { |r| r.required_defaults[:granite_action] }
      end
    end
  end
end
