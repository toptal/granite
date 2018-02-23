require 'granite/projector/translations/view_helper'

module Granite
  class Projector
    module Translations
      module Helper
        extend ActiveSupport::Concern

        included do
          delegate :scope_translation_args_by_projector, to: :projector_class
          helper_method :scope_translation_args_by_projector
          helper ViewHelper
        end

        def translate(*args)
          super(*scope_translation_args_by_projector(args, action_name: action_name))
        end
        alias t translate
      end
    end
  end
end
