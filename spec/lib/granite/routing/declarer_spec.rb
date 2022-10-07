RSpec.describe Granite::Routing::Declarer do
  subject { described_class }

  describe '.declare' do
    let(:routing) { ActionDispatch::Routing::Mapper.new(Rails.application.routes) }
    let(:route) { Granite::Routing::Route.new('ba/student/pause#modal') }

    it 'declares route according to route object' do
      subject.declare(routing, route)

      matched_route = Rails.application.routes.named_routes[route.as]

      expect(matched_route).to be_present
      expect(matched_route.required_defaults[:granite_action]).to eq 'ba/student/pause'
      expect(matched_route.required_defaults[:granite_projector]).to eq 'modal'
      expect(matched_route.verb).to eq('')
      expect(matched_route.app.app).to be_a Granite::Dispatcher
      expect(matched_route.path).to match '/pause/my_action'
    end

    context 'with explicit on: parameter' do
      it 'declares a route with appropriate path' do
        routing.resources :another_model do
          subject.declare(routing, route, on: :member)
        end

        matched_route = Rails.application.routes.named_routes['pause_another_model']

        expect(matched_route.path).to match '/another_model/:id/pause/my_action'
      end
    end

    context 'with explicit http verb via: :post' do
      it 'declares a route with appropriate verb' do
        routing.resources :another do
          subject.declare(routing, route, via: :post)
        end

        matched_route = Rails.application.routes.named_routes['another_pause']

        expect(matched_route.verb).to eq('POST')
      end
    end
  end

  describe '.reset_dispatcher' do
    it 'resets an instance of the Dispatcher' do
      expect(subject.dispatcher).to receive(:reset!)
      subject.reset_dispatcher
    end
  end
end
