module Granite::ProjectorHelpers
  extend ActiveSupport::Concern

  included do
    include RSpec::Rails::ControllerExampleGroup
    include RSpec::Rails::RequestExampleGroup
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
      setup_controller(&block)
      setup_view_context
      let(:projector) { controller.projector }
    end

    private

    def setup_controller(&block)
      define_method :setup_controller_request_and_response do
        @controller ||= instance_eval(&block).controller_class.new
        super()
      end
    end

    def setup_view_context
      before { Granite.view_context = controller.view_context }
      after { Granite.view_context = nil }
    end
  end
end

RSpec.configuration.define_derived_metadata(file_path: %r{spec/apq/projectors/}) { |metadata| metadata[:type] ||= :granite_projector }
RSpec.configuration.include Granite::ProjectorHelpers, type: :granite_projector
