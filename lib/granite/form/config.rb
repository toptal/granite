module Granite
  module Form
    class Config
      include Singleton

      attr_accessor :include_root_in_json, :i18n_scope, :logger, :primary_attribute, :base_class, :base_concern,
                    :_normalizers, :types

      def self.delegated
        public_instance_methods - superclass.public_instance_methods - Singleton.public_instance_methods
      end

      def initialize
        @include_root_in_json = false
        @i18n_scope = :granite
        @logger = Logger.new(STDERR)
        @primary_attribute = :id
        @_normalizers = {}
        @types = {}
      end

      def normalizer(name, &block)
        if block
          _normalizers[name.to_sym] = block
        else
          _normalizers[name.to_sym] or raise NormalizerMissing, name
        end
      end

      def typecaster(class_name, &block)
        types[class_name.to_s.camelize] = Class.new(Types::Object) do
          define_method(:typecast, &block)
        end
      end

      def type_for(klass)
        key = klass.ancestors.grep(Class).map(&:to_s).find(&types) or raise TypecasterMissing, klass
        types.fetch(key)
      end
    end
  end
end
