# frozen_string_literal: true

module Granite
  module Form
    module Types
      module ActiveSupport
        class TimeZone < Float
          private

          def typecast(value)
            case value
            when ::ActiveSupport::TimeZone
              value
            when ::TZInfo::Timezone
              ::ActiveSupport::TimeZone[value.name]
            when ::String, ::Numeric, ::ActiveSupport::Duration
              ::ActiveSupport::TimeZone[super || value]
            end
          end
        end
      end
    end
  end
end
