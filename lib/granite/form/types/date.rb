# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Date < Object
        private

        def typecast(value)
          value.try(:to_date)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
