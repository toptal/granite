# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Integer < Float
        private

        def typecast(value)
          super.try(:to_i)
        end
      end
    end
  end
end
