require 'granite/represents/attribute'

module Granite
  module Represents
    class Reflection < ActiveData::Model::Attributes::Reflections::Represents
      class << self
        def build(target, generated_methods, name, *args, &block)
          options = args.last

          reference = target.reflect_on_association(options[:of]) if target.respond_to?(:reflect_on_association)
          reference ||= target.reflect_on_attribute(options[:of]) if target.respond_to?(:reflect_on_attribute)

          target.validates_presence_of(reference.name) if reference

          super(target, generated_methods, name, *args, &block)
        end

        def attribute_class
          @attribute_class ||= Granite::Represents::Attribute
        end
      end
    end
  end
end
