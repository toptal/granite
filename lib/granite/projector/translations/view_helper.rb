module Granite
  class Projector
    module Translations
      module ViewHelper
        def translate(*args)
          super(*scope_translation_args_by_projector(args, action_name: action_name))
        end
        alias t translate
      end
    end
  end
end
