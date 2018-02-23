require 'granite/projector/error'

module Granite
  class Projector
    class ActionNotMountedError < Error
      def initialize(projector)
        super("Seems like #{projector.class} was not mounted. \
Do you have #{projector.action_class.name.underscore}##{projector.projector_name} declared in routes?", projector)
      end
    end

    module Helpers
      extend ActiveSupport::Concern

      def view_context
        Granite.view_context
      end
      alias h view_context

      def action_url(action, **options)
        action_path = controller_actions[action.to_sym].fetch(:as, action)
        params = required_params.merge(projector_action: action_path)

        Rails.application.routes.url_for(
          options.reverse_merge(url_options).merge!(params),
          corresponding_route.name
        )
      end

      def action_path(action, **options)
        action_url(action, **options, only_path: true)
      end

      private

      def required_params
        corresponding_route.required_parts
          .map { |name| [name, action.public_send(name)] }
          .to_h
      end

      def corresponding_route
        @corresponding_route ||= fetch_corresponding_route
      end

      def route_id
        [action_class.name.underscore, projector_name]
      end

      def url_options
        h&.url_options || {}
      end

      def fetch_corresponding_route
        Rails.application.routes.routes.granite_cache[*route_id] || fail(ActionNotMountedError, self)
      end
    end
  end
end
