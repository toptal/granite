module Granite
  class Projector
    module Translations
      module Helper
        include Granite::Projector::Translations
        extend ActiveSupport::Concern

        included do
          helper_method :scope_translation_args_by_projector
          helper_method :t, :translate
        end
      end
    end
  end
end
