module Granite
  # Core module for Rails extension. Implements some framework initialization,
  # like setting up proper load paths.
  class Railtie < ::Rails::Engine
    isolate_namespace Granite

    initializer 'granite.business_actions_paths', before: :set_autoload_paths do |app|
      app.config.paths.add 'apq', eager_load: true, glob: '{actions,projectors}{,/concerns}'
    end
  end
end
