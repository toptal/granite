module Granite
  module Form
    module Model
      module Associations
        module Reflections
          class ReferencesAny < Base
            def self.build(_target, generated_methods, name, *args)
              reflection = new(name, *args)
              generate_methods name, generated_methods
              reflection
            end

            def self.persistence_adapter(klass)
              adapter = klass.granite_persistence_adapter if klass.respond_to?(:granite_persistence_adapter)
              adapter or raise PersistenceAdapterMissing, klass
            end

            delegate :primary_key, to: :persistence_adapter

            def initialize(name, *args)
              @options = args.extract_options!
              @scope_proc = args.first
              @name = name.to_sym
            end

            def klass
              @klass ||= if options[:data_source].present?
                           options[:data_source].to_s.constantize
                         else
                           super
                         end
            end

            alias data_source klass

            def persistence_adapter
              @persistence_adapter ||= self.class.persistence_adapter(klass)
                                           .new(data_source, options[:primary_key], @scope_proc)
            end

            def read_source(object)
              object.read_attribute(reference_key)
            end

            def write_source(object, value)
              object.write_attribute(reference_key, value)
            end

            def embedded?
              false
            end

            def inspect
              "#{self.class.name.demodulize}(#{persistence_adapter.data_type})"
            end
          end
        end
      end
    end
  end
end
