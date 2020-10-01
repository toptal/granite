module Granite
  class Projector
    module Translations
      include ::Granite::Translations
      extend ActiveSupport::Concern

      class TranslationsWrapper
        include ActionView::Helpers::TranslationHelper

        class << self
          delegate :translate, to: :new
        end
      end

      module ClassMethods
        include Granite::Translations::ClassMethods

        alias scope_translation_args_by_projector scope_translation_args
      end
    end
  end
end
