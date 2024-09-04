module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class EmbedsAny < Base
            class << self
              def build(target, generated_methods, name, options = {}, &block)
                if block
                  options[:class] = proc do |reflection|
                    superclass = reflection.options[:class_name].to_s.presence.try(:constantize)
                    klass = build_class(superclass)
                    target.const_set(name.to_s.classify, klass)
                    klass.class_eval(&block)
                    klass
                  end
                end
                super
              end

              private def build_class(superclass)
                Class.new(superclass || Granite::Form.base_class) do
                  include Granite::Form::Model
                  include Granite::Form::Model::Associations
                  include Granite::Form::Model::Persistence
                  include Granite::Form::Model::Primary
                  include Granite::Form.base_concern if Granite::Form.base_concern
                end
              end
            end

            def klass
              @klass ||= if options[:class]
                           options[:class].call(self)
                         else
                           super
                         end
            end

            def inspect
              "#{self.class.name.demodulize}(#{klass})"
            end

            def embedded?
              true
            end
          end
        end
      end
    end
  end
end
