require 'granite/error'

module Granite
  class Action
    class Error < Granite::Error
      attr_reader :action

      def initialize(message, action = nil)
        @action = action
        super(message)
      end
    end
  end
end
