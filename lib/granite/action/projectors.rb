module Granite
  class Action
    module Projectors
      extend ActiveSupport::Concern

      class ProjectorsCollection
        def initialize(action_class)
          @action_class = action_class
          @storage = {}
          @cache = {}
        end

        def fetch(name)
          @cache[name.to_sym] ||= setup_projector(name)
        end

        def store(name, options, &block)
          old_options, old_blocks = fetch_options_and_blocks(name)
          @storage[name.to_sym] = [
            old_options.merge(options || {}),
            old_blocks + [block].compact
          ]
        end

        def names
          @storage.keys | (@action_class.superclass < Granite::Action ? @action_class.superclass._projectors.names : [])
        end

        private

        def setup_projector(name)
          options, blocks = fetch_options_and_blocks(name)

          projector_name = "#{name}_projector".classify
          controller_name = "#{name}_controller".classify

          projector = Class.new(projector_superclass(name, projector_name, options))
          projector.action_class = @action_class

          redefine_const(projector_name, projector)
          redefine_const(controller_name, projector.controller_class)

          blocks.each do |block|
            projector.class_eval(&block)
          end

          projector
        end

        def redefine_const(name, klass)
          if @action_class.const_defined?(name, false)
            @action_class.__send__(:remove_const, name)
            # TODO: this remove is confusing, would be better to raise? - ask @pyromaniac
          end
          @action_class.const_set(name, klass)
        end

        def fetch_options_and_blocks(name)
          name = name.to_sym
          options, blocks = @storage[name.to_sym]
          options ||= {}
          blocks ||= []

          [options, blocks]
        end

        def projector_superclass(name, projector_name, options)
          superclass = options[:class_name].presence.try(:constantize)
          superclass ||= @action_class.superclass._projectors.fetch(name) if @action_class.superclass < Granite::Action

          superclass || projector_name.safe_constantize || Granite::Projector
        end
      end

      module ClassMethods
        def _projectors
          @_projectors ||= ProjectorsCollection.new(self)
        end

        def projector_names
          _projectors.names
        end

        def projector(name, options = {}, &block)
          _projectors.store(name, options, &block)

          class_eval <<-METHOD, __FILE__, __LINE__ + 1
            def self.#{name}                                                # def self.foo
              _projectors.fetch(:#{name})                                   #   _projectors.fetch(:foo)
            end                                                             # end
                                                                            #
            def #{name}                                                     # def foo
              @#{name} ||= self.class._projectors.fetch(:#{name}).new(self) #   @foo ||= self.class._projectors.fetch(:foo).new(self)
            end                                                             # end
          METHOD
        end
      end
    end
  end
end
