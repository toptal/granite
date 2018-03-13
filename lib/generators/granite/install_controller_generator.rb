require 'rails/generators/base'

module Granite
  module Generators
    class InstallControllerGenerator < Rails::Generators::Base
      source_root File.expand_path('../../..', __dir__)

      desc 'Creates a Granite::Controller for further customization'

      def copy_controller
        copy_file 'app/controllers/granite/controller.rb'
      end
    end
  end
end
