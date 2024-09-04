module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class Base
            READ = ->(reflection, object) { object.read_attribute reflection.name }
            WRITE = ->(reflection, object, value) { object.write_attribute reflection.name, value }

            attr_reader :name, :options
            # AR compatibility
            attr_accessor :parent_reflection

            delegate :association_class, to: 'self.class'

            def self.build(target, generated_methods, name, options = {}, &_block)
              generate_methods name, generated_methods
              if options.delete(:validate) &&
                 target.respond_to?(:validates_nested) &&
                 !target.validates_nested?(name)
                target.validates_nested name
              end
              new(name, options)
            end

            def self.generate_methods(name, target)
              target.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name} force_reload = false
                association(:#{name}).reader(force_reload)
              end

              def #{name}= value
                association(:#{name}).writer(value)
              end
              RUBY
            end

            def self.association_class
              @association_class ||= "Granite::Form::Model::Associations::#{name.demodulize}".constantize
            end

            def initialize(name, options = {})
              @name = name.to_sym
              @options = options
            end

            def macro
              self.class.name.demodulize.underscore.to_sym
            end

            def klass
              @klass ||= (options[:class_name].presence || name.to_s.classify).to_s.constantize
            end

            # AR compatibility
            def belongs_to?
              false
            end

            def build_association(object)
              self.class.association_class.new object, self
            end

            def read_source(object)
              (options[:read] || READ).call(self, object)
            end

            def write_source(object, value)
              (options[:write] || WRITE).call(self, object, value)
            end

            def default(object)
              defaultizer = options[:default]
              if defaultizer.is_a?(Proc)
                if defaultizer.arity.nonzero?
                  defaultizer.call(object)
                else
                  object.instance_exec(&defaultizer)
                end
              else
                defaultizer
              end
            end

            def collection?
              true
            end
          end
        end
      end
    end
  end
end
