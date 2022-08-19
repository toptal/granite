module Granite
  module ContextProxy
    # Contains all the arbitrary data that is passed to BA with `with`
    class Data
      attr_reader :performer

      def self.wrap(data)
        if data.is_a?(self)
          data
        else
          new(**data || {})
        end
      end

      def initialize(performer: nil)
        @performer = performer
      end
    end
  end
end
