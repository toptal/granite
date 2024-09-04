module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Base
            attr_reader :name, :options

            class << self
              def build(_target, generated_methods, name, *args, &block)
                generate_methods name, generated_methods
                new(name, *args, &block)
              end

              def generate_methods(name, target) end

              def attribute_class
                @attribute_class ||= "Granite::Form::Model::Attributes::#{name.demodulize}".constantize
              end
            end

            def initialize(name, *args, &block)
              @name = name.to_s

              @options = args.extract_options!
              @options[:type] = args.first if args.first
              @options[:default] = block if block
            end

            def build_attribute(owner, raw_value = Granite::Form::UNDEFINED)
              type_definition = self.class::BuildTypeDefinition.new(owner, self).call
              attribute = self.class.attribute_class.new(type_definition)
              attribute.write_value(raw_value, origin: :persistence) unless raw_value == Granite::Form::UNDEFINED
              attribute
            end

            def type
              options[:type]
            end

            def readonly
              options[:readonly]
            end

            def enum
              options[:enum] || options[:in]
            end

            def keys
              @keys ||= Array.wrap(options[:keys]).map(&:to_s)
            end

            def inspect_reflection
              "#{name}: #{type}"
            end
          end
        end
      end
    end
  end
end
