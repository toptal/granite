require 'granite/error'

module Granite
  class Projector
    class Error < Granite::Error
      attr_reader :projector

      def initialize(message, projector = nil)
        @projector = projector
        super(message)
      end
    end
  end
end
