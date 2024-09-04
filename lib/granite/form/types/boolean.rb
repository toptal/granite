# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Boolean < Object
        MAPPING = {
          1 => true,
          0 => false,
          '1' => true,
          '0' => false,
          't' => true,
          'f' => false,
          'T' => true,
          'F' => false,
          true => true,
          false => false,
          'true' => true,
          'false' => false,
          'TRUE' => true,
          'FALSE' => false,
          'y' => true,
          'n' => false,
          'yes' => true,
          'no' => false
        }.freeze

        def self.typecast(value)
          MAPPING[value]
        end

        private

        def typecast(value)
          self.class.typecast(value)
        end
      end
    end
  end
end
