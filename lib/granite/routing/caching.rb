require 'granite/routing/cache'

module Granite
  module Routing
    module Caching
      def granite_cache
        @granite_cache ||= Cache.new(self)
      end

      def clear_cache!
        @granite_cache = nil
        super
      end
    end
  end
end

ActionDispatch::Journey::Routes.prepend Granite::Routing::Caching
