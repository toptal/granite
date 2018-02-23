module Granite
  module PerformerProxy
    # Proxy helps to wrap the following method call with
    # performer-enabled context.
    #
    class Proxy
      def initialize(klass, performer)
        @klass = klass
        @performer = performer
      end

      def inspect
        "<#{@klass}PerformerProxy #{@performer}>"
      end

      def method_missing(method, *args, &block)
        if @klass.respond_to?(method)
          @klass.with_proxy_performer(@performer) do
            @klass.public_send(method, *args, &block)
          end
        else
          super
        end
      end

      def respond_to_missing?(*args)
        @klass.respond_to?(*args)
      end
    end
  end
end
