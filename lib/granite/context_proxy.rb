require 'granite/context_proxy/data'
require 'granite/context_proxy/proxy'

module Granite
  # This concern contains class methods used for actions and projectors
  #
  module ContextProxy
    extend ActiveSupport::Concern

    module ClassMethods
      def using(data)
        Proxy.new(self, Data.wrap(data))
      end

      def as(performer)
        using(performer: performer)
      end

      def with_context(context)
        key = proxy_context_key
        old_context = Thread.current[key]
        Thread.current[key] = context
        yield
      ensure
        Thread.current[key] = old_context
      end

      def proxy_context
        Thread.current[proxy_context_key]
      end

      private

      def proxy_context_key
        :"granite_proxy_performer_#{hash}"
      end
    end
  end
end
