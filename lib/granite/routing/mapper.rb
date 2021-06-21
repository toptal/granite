require 'granite/routing/declarer'
require 'granite/routing/route'

module Granite
  module Routing
    module Mapper
      def granite(projector_path, **options)
        route = Route.new(projector_path, **options.extract!(:path, :as, :projector_prefix))
        Declarer.declare(self, route, **options)
      end
    end
  end
end

ActionDispatch::Routing::Mapper.include Granite::Routing::Mapper
