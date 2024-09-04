# frozen_string_literal: true

module Granite
  module Form
    module Types
      class Object
        attr_reader :reflection, :owner, :type

        delegate :name, to: :reflection

        def initialize(type, reflection, owner)
          @type = type
          @reflection = reflection
          @owner = owner
        end

        def build_duplicate(reflection, owner)
          self.class.new(type, reflection, owner)
        end

        def prepare(value)
          enumerize(ensure_type(value))
        end

        def enum
          source = owner.evaluate(reflection.enum)

          case source
          when ::Range
            source.to_a
          when ::Set
            source
          else
            ::Array.wrap(source)
          end.to_set
        end

        private

        def ensure_type(value)
          if value.instance_of?(type)
            value
          elsif !value.nil?
            typecast(value)
          end
        end

        def typecast(value)
          value if value.is_a?(type)
        end

        def enumerize(value)
          set = enum if reflection.enum
          value if !set || (set.none? || set.include?(value))
        end
      end
    end
  end
end
