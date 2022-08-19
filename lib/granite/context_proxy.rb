require 'granite/context_proxy/data'
require 'granite/context_proxy/proxy'

module Granite
  # This concern contains class methods used for actions and projectors
  #
  module ContextProxy
    extend ActiveSupport::Concern

    module ClassMethods
      PROXY_CONTEXT_KEY = :granite_proxy_context

      def with(data)
        Proxy.new(self, Data.wrap(data))
      end

      def as(performer)
        with(performer: performer)
      end

      def with_context(context)
        old_context = proxy_context
        Thread.current[PROXY_CONTEXT_KEY] = context
        yield
      ensure
        Thread.current[PROXY_CONTEXT_KEY] = old_context
      end

      def proxy_context
        Thread.current[PROXY_CONTEXT_KEY]
      end
    end
  end
end
