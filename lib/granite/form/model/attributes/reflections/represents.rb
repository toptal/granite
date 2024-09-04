module Granite
  module Form
    module Model
      module Attributes
        module Reflections
          class Represents < Attribute
            def self.attribute_class
              Attributes::Represents
            end

            def self.build(target, generated_methods, name, *args, &block)
              options = args.extract_options!

              reference = target.reflect_on_association(options[:of]) if target.respond_to?(:reflect_on_association)
              reference ||= target.reflect_on_attribute(options[:of]) if target.respond_to?(:reflect_on_attribute)
              options[:of] = reference.name if reference

              if options.fetch(:validate_reference, true)
                validates_nested = target.respond_to?(:validates_nested) && !target.validates_nested?(options[:of])
                target.validates_nested(options[:of]) if validates_nested
                target.validates_presence_of(options[:of]) unless target.validates_presence?(options[:of])
              end

              super(target, generated_methods, name, *args, options, &block)
            end

            def initialize(name, options)
              super
              raise ArgumentError, "Undefined reference for `#{name}`" if reference.blank?
            end

            def type
              Object
            end

            def reference
              @reference ||= options[:of].to_s
            end

            def column
              @column ||= options[:column].presence.try(:to_s) || name
            end

            def reader
              @reader ||= options[:reader].presence.try(:to_s) || column
            end

            def reader_before_type_cast
              @reader_before_type_cast ||= "#{reader}_before_type_cast"
            end

            def writer
              @writer ||= "#{options[:writer].presence || column}="
            end

            def inspect_reflection
              "#{name}: (represents)"
            end
          end
        end
      end
    end
  end
end
