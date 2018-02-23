require 'granite/performer_proxy'

module Granite
  class Action
    # Performer module is responsible for setting performer for action.
    #
    module Performer
      extend ActiveSupport::Concern

      included do
        include PerformerProxy
        attr_reader :performer
      end

      def initialize(*args)
        @performer = self.class.proxy_performer
        super
      end

      delegate :id, to: :performer, prefix: true, allow_nil: true
    end
  end
end
