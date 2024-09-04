require 'granite/form/model/associations/collection/proxy'
require 'granite/form/model/associations/collection/embedded'

require 'granite/form/model/associations/reflections/base'
require 'granite/form/model/associations/reflections/singular'
require 'granite/form/model/associations/reflections/embeds_any'
require 'granite/form/model/associations/reflections/embeds_one'
require 'granite/form/model/associations/reflections/embeds_many'
require 'granite/form/model/associations/reflections/references_any'
require 'granite/form/model/associations/reflections/references_one'
require 'granite/form/model/associations/reflections/references_many'

require 'granite/form/model/associations/base'
require 'granite/form/model/associations/embeds_any'
require 'granite/form/model/associations/embeds_one'
require 'granite/form/model/associations/embeds_many'
require 'granite/form/model/associations/references_any'
require 'granite/form/model/associations/references_one'
require 'granite/form/model/associations/references_many'

require 'granite/form/model/associations/nested_attributes'
require 'granite/form/model/associations/validations'

module Granite
  module Form
    module Model
      module Associations
        extend ActiveSupport::Concern

        included do
          include NestedAttributes

          class_attribute :_associations, :_association_aliases, instance_reader: false, instance_writer: false
          self._associations = {}
          self._association_aliases = {}

          delegate :association_names, to: 'self.class'

          {
            embeds_many: Reflections::EmbedsMany,
            embeds_one: Reflections::EmbedsOne,
            references_one: Reflections::ReferencesOne,
            references_many: Reflections::ReferencesMany
          }.each do |(name, reflection_class)|
            define_singleton_method name do |*args, &block|
              reflection = reflection_class.build self, generated_associations_methods, *args, &block
              self._associations = _associations.merge(reflection.name => reflection)
              reflection
            end
          end
        end

        module ClassMethods
          def reflections
            _associations
          end

          def alias_association(alias_name, association_name)
            reflection = reflect_on_association(association_name)
            raise ArgumentError, "Can't alias undefined association `#{attribute_name}` on #{self}" unless reflection

            reflection.class.generate_methods alias_name, generated_associations_methods
            self._association_aliases = _association_aliases.merge(alias_name.to_sym => reflection.name)
            reflection
          end

          def reflect_on_association(name)
            name = name.to_sym
            _associations[_association_aliases[name] || name]
          end

          def association_names
            _associations.keys
          end

          private

          def attributes_for_inspect
            (_associations.map do |name, reflection|
              "#{name}: #{reflection.inspect}"
            end + [super]).join(', ')
          end

          def generated_associations_methods
            @generated_associations_methods ||= const_set(:GeneratedAssociationsMethods, Module.new)
                                                .tap { |proxy| include proxy }
          end
        end

        def ==(other)
          super && association_names.all? do |association|
            public_send(association) == other.public_send(association)
          end
        end

        alias eql? ==

        def association(name)
          reflection = self.class.reflect_on_association(name)
          return unless reflection

          (@_associations ||= {})[reflection.name] ||= reflection.build_association(self)
        end

        private

        def attributes_for_inspect
          (association_names.map do |name|
            association = association(name)
            "#{name}: #{association.inspect}"
          end + [super]).join(', ')
        end
      end
    end
  end
end
