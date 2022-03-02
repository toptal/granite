RSpec.describe Granite::Routing::Cache do
  subject { described_class.new(routes) }
  let(:action_route) do
    instance_double('ActionDispatch::Journey::Route', required_defaults: {granite_action: 'test', granite_projector: 'simple'})
  end
  let(:another_action_route) do
    instance_double('ActionDispatch::Journey::Route', required_defaults: {granite_action: 'test2', granite_projector: 'simple'})
  end
  let(:regular_route) do
    instance_double('ActionDispatch::Journey::Route', required_defaults: {})
  end
  let(:routes) do
    [action_route, another_action_route, regular_route]
  end

  describe '#[]' do
    it 'returns route with matched action & projector' do
      expect(subject[:test, :simple]).to eq action_route
    end

    it 'returns nil if no route found' do
      expect(subject[:foo, :bar]).to be_nil
    end
  end
end
