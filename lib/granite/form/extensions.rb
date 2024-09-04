class Boolean; end unless defined?(Boolean)

begin
  require 'uuidtools'
rescue LoadError
  nil
else
  module Granite
    module Form
      class UUID < UUIDTools::UUID
        def as_json(*_)
          to_s
        end

        def to_param
          to_s
        end

        def self.parse_string(value)
          return nil if value.empty?

          if value.length == 36
            parse value
          elsif value.length == 32
            parse_hexdigest value
          else
            parse_raw value
          end
        end

        def inspect
          "#<Granite::Form::UUID:#{self}>"
        end
      end
    end
  end
end
