module Granite
  module ContextProxy
    # Proxy which wraps the following method calls with BA context.
    #
    class Proxy
      def initialize(klass, context)
        @klass = klass
        @context = context
      end

      def inspect
        "<#{@klass}ContextProxy #{@context}>"
      end

      ruby2_keywords def method_missing(method, *args, &block)
        if @klass.respond_to?(method)
          @klass.with_context(@context) do
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
