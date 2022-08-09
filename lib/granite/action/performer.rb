require 'granite/context_proxy'

module Granite
  class Action
    # Performer module is responsible for setting performer for action.
    #
    module Performer
      extend ActiveSupport::Concern

      included do
        include ContextProxy
        attr_reader :ctx
      end

      def initialize(*args)
        @ctx = self.class.proxy_context
        super
      end

      delegate :performer, to: :ctx, allow_nil: true
      delegate :id, to: :performer, prefix: true, allow_nil: true
    end
  end
end
