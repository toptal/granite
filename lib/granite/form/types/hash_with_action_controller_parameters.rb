# frozen_string_literal: true

module Granite
  module Form
    module Types
      class HashWithActionControllerParameters < Object
        private

        def typecast(value)
          case value
          when ActionController::Parameters
            value.to_h if value.permitted?
          when ::Hash
            value
          end
        end
      end
    end
  end
end
