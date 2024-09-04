# frozen_string_literal: true

module Granite
  module Form
    module Types
      class UUID < Object
        private

        def typecast(value)
          case value
          when UUIDTools::UUID
            Granite::Form::UUID.parse_raw value.raw
          when Granite::Form::UUID
            value
          when ::String
            Granite::Form::UUID.parse_string value
          when ::Integer
            Granite::Form::UUID.parse_int value
          end
        end
      end
    end
  end
end
