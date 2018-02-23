module Granite
  class Projector
    module Translations
      extend ActiveSupport::Concern

      class TranslationsWrapper
        include ActionView::Helpers::TranslationHelper
      end

      def translate(*args)
        TranslationsWrapper.new.translate(*self.class.scope_translation_args_by_projector(args))
      end
      alias t translate

      module ClassMethods
        def scope_translation_args_by_projector(args, action_name: nil)
          options = args.extract_options!

          lookups = expand_relative_key(args.first, action_name).map(&:to_sym)
          lookups += [options[:default]]
          lookups = lookups.flatten.compact

          key = lookups.shift
          options[:default] = lookups

          [key, options]
        end

        private

        def expand_relative_key(key, action_name = nil)
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
          base_keys = [:"#{projector_name}.#{undotted_key}"]
          base_keys.unshift :"#{projector_name}.#{action_name}.#{undotted_key}" if action_name
          base_keys
        end
      end
    end
  end
end
