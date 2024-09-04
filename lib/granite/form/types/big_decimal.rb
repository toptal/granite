# frozen_string_literal: true

module Granite
  module Form
    module Types
      class BigDecimal < Object
        private

        def typecast(value)
          BigDecimal(Float(value).to_s) if value
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
