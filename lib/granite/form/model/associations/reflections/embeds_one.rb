module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class EmbedsOne < EmbedsAny
            include Singular

            def self.build(target, generated_methods, name, options = {}, &block)
              if target < Granite::Form::Model::Attributes
                target.add_attribute(Granite::Form::Model::Attributes::Reflections::Base, name,
                                     type: Object)
              end
              options[:validate] = true unless options.key?(:validate)
              super
            end

            def self.generate_methods(name, target)
              super

              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
                def build_#{name} attributes = {}
                  association(:#{name}).build(attributes)
                end
              RUBY
            end
          end
        end
      end
    end
  end
end
