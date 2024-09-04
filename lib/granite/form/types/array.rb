# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Array < Object
        private

        def typecast(value)
          if value.is_a?(::String)
            value.split(',').map(&:strip)
          else
            super
          end
        end
      end
    end
  end
end
