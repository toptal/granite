module Granite
  module Form
    module Model
      module Scopes
        extend ActiveSupport::Concern

        included do
          class_attribute :_scope_base
          scopify
        end

        module ScopeProxy
          extend ActiveSupport::Concern

          def self.for(model)
            klass = Class.new(model._scope_base) do
              include Granite::Form::Model::Scopes::ScopeProxy
            end
            klass.define_singleton_method(:_scope_model) { model }
            model.const_set('ScopeProxy', klass)
          end

          included do
            def initialize(source = nil, trust = false)
              source ||= self.class.superclass.new

              unless trust && source.is_a?(self.class)
                source.each do |entity|
                  unless entity.is_a?(self.class._scope_model)
                    raise AssociationTypeMismatch.new(self.class._scope_model,
                                                      entity.class)
                  end
                end
              end

              super(source)
            end
          end

          def respond_to_missing?(method, _)
            super || self.class._scope_model.respond_to?(method)
          end

          # rubocop-0.52.1 doesn't understand that `#respond_to_missing?` is defined above
          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0')
            def method_missing(method, *args, **kwargs, &block)
              with_scope do
                model = self.class._scope_model
                if model.respond_to?(method)
                  result = model.public_send(method, *args, **kwargs, &block)
                  result.is_a?(Granite::Form::Model::Scopes) ? result : model.scope_class.new(result)
                else
                  super
                end
              end
            end
          elsif Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7.0')
            def method_missing(method, *args, **kwargs, &block)
              with_scope do
                model = self.class._scope_model
                if model.respond_to?(method)
                  model.public_send(method, *args, **kwargs, &block)
                else
                  super
                end
              end
            end
          else
            # up to 2.6.x
            def method_missing(method, *args, &block)
              with_scope do
                model = self.class._scope_model
                if model.respond_to?(method)
                  model.public_send(method, *args, &block)
                else
                  super
                end
              end
            end
          end
          def with_scope
            previous_scope = self.class._scope_model.current_scope
            self.class._scope_model.current_scope = self
            result = yield
            self.class._scope_model.current_scope = previous_scope
            result
          end
        end

        module ClassMethods
          def scopify(scope_base = Array)
            self._scope_base = scope_base
          end

          def scope_class
            @scope_class ||= Granite::Form::Model::Scopes::ScopeProxy.for(self)
          end

          def scope(*args)
            if args.empty?
              current_scope
            else
              scope_class.new(*args)
            end
          end

          def current_scope=(value)
            @current_scope = value
          end

          def current_scope
            @current_scope ||= scope_class.new
          end
        end
      end
    end
  end
end
