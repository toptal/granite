module Granite::ProjectorHelpers
  extend ActiveSupport::Concern
  include RSpec::Rails::ControllerExampleGroup

  included do
    before { Granite::Routing::Declarer.dispatcher.unmemoize_all }
  end

  module ClassMethods
    def draw_routes(&block)
      before(:all) do
        routes = Rails.application.routes
        routes.disable_clear_and_finalize = true
        routes.draw(&block)
      end

      after(:all) do
        Rails.application.routes.disable_clear_and_finalize = false
        Rails.application.reload_routes!
        Rails.application.routes.routes.clear_cache!
      end
    end

    def projector(&block)
      setup_controller
      setup_view_context
      let(:projector_class, &block)
      let(:projector) { controller.projector }
    end

    private

    def setup_controller
      define_method :setup_controller_request_and_response do
        @controller ||= projector_class.controller_class.new
        super()
      end
    end

    def setup_view_context
      before { Granite.view_context = controller.view_context }
      after { Granite.view_context = nil }
    end
  end

  # Overrides ActionController::TestCase::Behavior#process to include granite_action and granite_projector
  def process(action, **options)
    projector_params = {granite_action: projector_class.action_name, granite_projector: projector_class.projector_name}
    super(action, **options, params: projector_params.reverse_merge(options[:params] || {}))
  end
end

RSpec.configuration.define_derived_metadata(file_path: %r{spec/apq/projectors/}) { |metadata| metadata[:type] ||= :granite_projector }
RSpec.configuration.include Granite::ProjectorHelpers, type: :granite_projector
