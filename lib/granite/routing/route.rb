module Granite
  module Routing
    class Route
      attr_reader :projector_path, :action_path, :projector_name

      def initialize(projector_path, path: nil, as: nil, projector_prefix: false)
        @projector_path = projector_path
        @action_path, @projector_name = projector_path.split('#')
        @path = path
        @as = as

        @action_name = @action_path.split('/').last
        @action_name = "#{@projector_name}_#{@action_name}" if projector_prefix
      end

      def path
        "#{@path || action_name}(/:projector_action)"
      end

      def as
        @as || action_name
      end

      private

      attr_reader :action_name
    end
  end
end
