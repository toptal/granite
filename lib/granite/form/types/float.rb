# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Float < Object
        private

        def typecast(value)
          Float(value)
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
