module Granite
  class Projector
    module Translations
      include ActionView::Helpers::TranslationHelper

      def i18n_scopes
        Granite::Translations.combine_paths(action_class.i18n_scopes, [:"#{projector_name}"])
      end

      def translate(*args, **options)
        key, options = Granite::Translations.scope_translation_args(i18n_scopes, *args, **options)
        super(key, **options)
      end

      alias t translate
    end
  end
end
