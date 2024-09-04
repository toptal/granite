# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Time < Object
        private

        def typecast(value)
          value.is_a?(::String) && ::Time.zone ? ::Time.zone.parse(value) : value.try(:to_time)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
