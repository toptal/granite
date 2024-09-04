# frozen_string_literal: true

module Granite
  module Form
    module Types
      class String < Object
        private

        def typecast(value)
          value.to_s
        end
      end
    end
  end
end
