require 'granite/performer_proxy/proxy'

module Granite
  # This concern contains class methods used for actions and projectors
  #
  module PerformerProxy
    extend ActiveSupport::Concern

    module ClassMethods
      def as(performer)
        Proxy.new(self, performer)
      end

      def with_proxy_performer(performer)
        key = proxy_performer_key
        old_performer = Thread.current[key]
        Thread.current[key] = performer
        yield
      ensure
        Thread.current[key] = old_performer
      end

      def proxy_performer
        Thread.current[proxy_performer_key]
      end

      private

      def proxy_performer_key
        :"granite_proxy_performer_#{hash}"
      end
    end
  end
end
