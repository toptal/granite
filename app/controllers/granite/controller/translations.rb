module Granite
  class Controller
    module Translations
      def i18n_scopes
        Granite::Translations.combine_paths(projector.i18n_scopes, [*action_name, nil])
      end

      def translate(*args, **options)
        key, options = Granite::Translations.scope_translation_args(i18n_scopes, *args, **options)
        super(key, **options)
      end

      alias t translate
    end
  end
end
