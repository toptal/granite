module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class ReferenceOne < Base
            def self.generate_methods(name, target)
              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}
                attribute('#{name}').read
              end

              def #{name}= value
                attribute('#{name}').write(value)
              end

              def #{name}?
                attribute('#{name}').query
              end

              def #{name}_before_type_cast
                attribute('#{name}').read_before_type_cast
              end
              RUBY
            end

            def inspect_reflection
              "#{name}: (reference)"
            end

            def association
              @association ||= options[:association].to_s
            end
          end
        end
      end
    end
  end
end
