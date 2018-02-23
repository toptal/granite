module Granite
  class Action
    module Translations
      extend ActiveSupport::Concern

      def translate(*args)
        I18n.translate(*self.class.scope_translation_args(args))
      end
      alias t translate

      module ClassMethods
        def scope_translation_args(args)
          options = args.extract_options!

          lookups = expand_relative_key(args.first).map(&:to_sym)
          lookups += [options[:default]]
          lookups = lookups.flatten.compact

          key = lookups.shift
          options[:default] = lookups

          [key, options]
        end

        private

        def expand_relative_key(key)
          return [key] unless key.is_a?(String) && key.start_with?('.')

          base_key = key.sub(/^\./, '')

          lookup_ancestors.map do |klass|
            :"#{klass.i18n_scope}.#{klass.model_name.i18n_key}.#{base_key}"
          end.flatten + [base_key]
        end
      end
    end
  end
end
