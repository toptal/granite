module Granite
  module Translations
    extend ActiveSupport::Concern

    TranslationsWrapper = I18n

    def translate(*args, **kwargs)
      action_name = public_send(:action_name) if respond_to?(:action_name)

      *i18n_args, i18n_options = self.class.scope_translation_args([*args, kwargs], action_name: action_name)
      self.class.const_get('TranslationsWrapper').translate(*i18n_args, **i18n_options)
    end
    alias t translate

    module ClassMethods
      def scope_translation_args(args, action_name: nil)
        options = args.extract_options!

        lookups = expand_relative_key(args.first, action_name)
          .map(&:to_sym)
          .push(options[:default])
          .flatten
          .compact

        key = lookups.shift
        options[:default] = lookups

        [key, options]
      end

      private

      def action_class
        self
      end

      def expand_relative_key(key, action_name)
        return [key] unless key.is_a?(String) && key.start_with?('.')

        base_keys = extract_base_keys(key, action_name)

        action_class.lookup_ancestors.map do |klass|
          base_keys.map do |base_key|
            :"#{klass.i18n_scope}.#{klass.model_name.i18n_key}.#{base_key}"
          end
        end.flatten + base_keys
      end

      def extract_base_keys(key, action_name)
        undotted_key = key.sub(/^\./, '')
        projector_name = public_send(:projector_name) if respond_to?(:projector_name)

        return [undotted_key] if projector_name.nil?

        base_keys = [:"#{projector_name}.#{undotted_key}"]
        base_keys.unshift :"#{projector_name}.#{action_name}.#{undotted_key}" if action_name
        base_keys
      end
    end
  end
end
