module Granite
  class Action
    module Translations
      extend ActiveSupport::Concern

      module ClassMethods
        def i18n_scope
          :granite_action
        end

        def i18n_scopes
          lookup_ancestors.flat_map do |klass|
            :"#{klass.i18n_scope}.#{klass.model_name.i18n_key}"
          end + [nil]
        end
      end

      def translate(*args, **options)
        key, options = Granite::Translations.scope_translation_args(self.class.i18n_scopes, *args, **options)
        I18n.t(key, **options)
      end
      alias t translate
    end
  end
end
