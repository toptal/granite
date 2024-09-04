module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Attribute < Base
            def self.attribute_class
              Granite::Form::Model::Attributes::Attribute
            end

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

              def #{name}_came_from_user?
                attribute('#{name}').came_from_user?
              end

              def #{name}_default
                attribute('#{name}').default
              end

              def #{name}_values
                attribute('#{name}').enum.to_a
              end
              RUBY
            end

            def defaultizer
              @defaultizer ||= options[:default]
            end

            def normalizers
              @normalizers ||= Array.wrap(options[:normalize] || options[:normalizer] || options[:normalizers])
            end
          end
        end
      end
    end
  end
end
