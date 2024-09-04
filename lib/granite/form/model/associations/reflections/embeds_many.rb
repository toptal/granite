module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class EmbedsMany < EmbedsAny
            def self.build(target, generated_methods, name, options = {}, &block)
              if target < Granite::Form::Model::Attributes
                target.add_attribute(Granite::Form::Model::Attributes::Reflections::Base, name,
                                     type: Object)
              end
              options[:validate] = true unless options.key?(:validate)
              super
            end
          end
        end
      end
    end
  end
end
