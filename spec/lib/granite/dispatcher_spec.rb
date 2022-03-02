RSpec.describe Granite::Dispatcher do
  subject(:dispatcher) { described_class.new }

  before do
    stub_class(:projector, Granite::Projector) do
      get :confirm do
      end

      post :perform, as: '' do
      end
    end

    stub_class(:action, Granite::Action) do
      projector :dummy, class_name: 'Projector'
    end
  end

  let(:params) { {granite_action: 'action', granite_projector: 'dummy'} }

  describe '#call' do
    specify { expect { dispatcher.call({}) }.to raise_error 'Dispatcher can\'t be used as a Rack app.' }
  end

  describe '#constraints' do
    subject { dispatcher.constraints.all? { |c| c.call(req) } }
    let(:req) { instance_double('ActionDispatch::Request', env: env, params: params, request_method_symbol: request_method) }
    let(:env) { {} }
    let(:params) { super().merge(projector_action: 'confirm') }
    let(:request_method) { :get }

    context 'when BA projector has appropriate action defined' do
      it { is_expected.to be(true) }
    end

    context 'when request has different request method' do
      let(:request_method) { :post }

      it { is_expected.to be(false) }
    end

    context 'when request has different action' do
      let(:params) { super().merge(projector_action: 'undefined') }

      it { is_expected.to be(false) }
    end

    context 'when request has invalid granite params' do
      before do
        stub_class(:action_without_projectors, Granite::Action)
      end

      let(:params) { {granite_action: 'action_without_projectors', granite_projector: 'dummy', projector_action: 'confirm'} }

      it { is_expected.to be(false) }
    end
  end

  describe '#serve' do
    let(:controller_class) { Action.dummy.controller_class }
    let(:controller_action) { object_spy(->(_env) {}) }
    let(:env) { {} }
    let(:params) { super().merge(projector_action: 'confirm') }
    let(:request_method) { :get }
    let(:req) { instance_double('ActionDispatch::Request', env: env, params: params, request_method_symbol: request_method) }

    before do
      allow(controller_class).to receive(:action) { controller_action }
    end

    it 'finds the controller action by name in the specified projector' do
      subject.serve(req)

      expect(controller_class).to have_received(:action).with(:confirm)
    end

    it 'calls the controller action by name in the specified business action' do
      subject.serve(req)

      expect(controller_action).to have_received(:call).with(env)
    end

    context 'when projector action is nil' do
      let(:params) { super().except(:projector_action) }
      let(:request_method) { :post }

      it 'finds the controller action by name in the specified projector' do
        subject.serve(req)

        expect(controller_class).to have_received(:action).with(:perform)
      end
    end
  end

  describe '#controller' do
    subject { dispatcher.controller(params) }

    context 'when projector exists' do
      it { is_expected.to eq Action.dummy.controller_class }
    end

    context 'when projector does not exist' do
      let(:params) { super().merge(granite_projector: 'invalid') }
      it { is_expected.to be_nil }
    end
  end

  describe '#prepare_params!' do
    subject { dispatcher.prepare_params!(params) }
    let(:params) { double }
    it('does nothing') { is_expected.to eq params }
  end

  describe '#reset!' do
    it 'unmemoize all cached methods' do
      expect(subject).to receive(:unmemoize_all)
      subject.reset!
    end
  end
end
