module Granite
  class Action
    class Precondition < BasicObject
      UNDEFINED = ::Object.new.freeze

      def self.description(text = UNDEFINED)
        case text
        when UNDEFINED
          @description
        else
          @description = text
        end
      end

      def initialize(context)
        @context = context
      end

      def call(*)
        fail NotImplementedError, "#call method must be implemented for #{self.class}"
      end

      def method_missing(method_name, *args, &blk)
        super unless @context.respond_to?(method_name)

        @context.__send__(method_name, *args, &blk)
      end

      def respond_to_missing?(method_name, _include_private = false)
        @context.respond_to?(method_name)
      end

      private

      attr_reader :context
    end
  end
end
