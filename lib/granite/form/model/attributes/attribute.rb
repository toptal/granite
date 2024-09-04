module Granite
  module Form
    module Model
      module Attributes
        class Attribute < Base
          delegate :defaultizer, :enumerizer, :normalizers, to: :reflection

          def write(value)
            return if readonly?

            pollute do
              write_value value
            end
          end

          def read
            variable_cache(:value) do
              normalize(type_definition.prepare(read_before_type_cast))
            end
          end

          def read_before_type_cast
            variable_cache(:value_before_type_cast) do
              defaultize(@value_cache)
            end
          end

          def default
            owner.evaluate_if_proc(defaultizer)
          end

          def defaultize(value, default_value = nil)
            !defaultizer.nil? && value.nil? ? default_value || default : value
          end

          def normalize(value)
            if normalizers.none?
              value
            else
              normalizers.inject(value) do |val, normalizer|
                case normalizer
                when Proc
                  owner.evaluate(normalizer, val)
                when Hash
                  normalizer.inject(val) do |v, (name, options)|
                    Granite::Form.normalizer(name).call(v, options, self)
                  end
                else
                  Granite::Form.normalizer(normalizer).call(val, {}, self)
                end
              end
            end
          end
        end
      end
    end
  end
end
