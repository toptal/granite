RSpec.describe Granite::Projector::ControllerActions, type: :granite_projector do
  prepend_before do
    stub_class(:projector, Granite::Projector) do
      get :confirm do
        render json: {success: true, action: 'confirm'}
      end

      post :perform do
        render json: {success: true, action: 'perform'}
      end

      get :custom, as: '' do
        render json: {success: true, action: 'custom'}
      end

      post :custom_post, as: '' do
        render json: {success: true, action: 'custom_post'}
      end
    end
    stub_class(:descendant, Projector)
    stub_class(:dummy_action, Granite::Action) do
      projector :dummy, class_name: 'Projector'
      allow_if { true }
      attribute :name, String
    end
  end

  describe '.action' do
    before do
      Projector.action(:first, method: 'post') {}
      Descendant.action(:second, method: 'put') {}
    end

    specify { expect(Projector.action(:first)).to eq(method: 'post') }
    specify { expect(Descendant.action('first')).to eq(method: 'post') }

    specify { expect(Projector.action(:second)).to be_nil }
    specify { expect(Descendant.action('second')).to eq(method: 'put') }

    specify { expect(Projector.controller_class).to be_method_defined(:first) }
    specify { expect(Descendant.controller_class).to be_method_defined(:first) }

    specify { expect(Projector.controller_class).not_to be_method_defined(:second) }
    specify { expect(Descendant.controller_class).to be_method_defined(:second) }
  end

  ActionDispatch::Routing::HTTP_METHODS.each do |method|
    describe ".#{method}" do
      before { Projector.public_send(method, :first) {} }

      specify { expect(Projector.action(:first)).to eq(method: method) }
      specify { expect(Descendant.action('first')).to eq(method: method) }
    end
  end

  describe '.action_for' do
    specify { expect(Projector.action_for(:get, 'confirm')).to eq :confirm }
    specify { expect(Projector.action_for(:get, 'perform')).to be_nil }
    specify { expect(Projector.action_for(:get, '')).to eq :custom }
    specify { expect(Projector.action_for(:post, '')).to eq :custom_post }

    context 'with custom name' do
      before do
        stub_class(:projector, Granite::Projector) do
          get(:confirm, as: 'test') {}
        end
      end

      specify { expect(Projector.action_for(:get, 'confirm')).to be_nil }
      specify { expect(Projector.action_for(:get, 'test')).to eq :confirm }
    end
  end

  describe 'routes' do
    projector { DummyAction.dummy }

    context 'with no subject' do
      draw_routes do
        resources :students do
          granite 'dummy_action#dummy', on: :collection
        end
      end

      describe '##{action}_url' do
        specify { expect(projector.confirm_url(foo: 'string')).to eq('http://test.host/students/dummy_action/confirm?foo=string') }
        specify { expect(projector.perform_url(anchor: 'ok')).to eq('http://test.host/students/dummy_action/perform#ok') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_url('anchor' => 'ok')).to eq('http://test.host/students/dummy_action/perform#ok') }
        end
      end

      describe '##{action}_path' do
        specify { expect(projector.confirm_path).to eq('/students/dummy_action/confirm') }
        specify { expect(projector.perform_path(bar: 'string')).to eq('/students/dummy_action/perform?bar=string') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_path('bar' => 'string')).to eq('/students/dummy_action/perform?bar=string') }
        end
      end
    end

    context 'with subject' do
      draw_routes do
        resources :students do
          granite 'dummy_action#dummy', on: :member
        end
      end

      before do
        DummyAction.subject :role
        controller.params[:role] = Role.new(id: 42)
      end

      describe '##{action}_url' do
        specify { expect(projector.confirm_url(foo: 'string')).to eq('http://test.host/students/42/dummy_action/confirm?foo=string') }
        specify { expect(projector.perform_url(anchor: 'ok')).to eq('http://test.host/students/42/dummy_action/perform#ok') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_url('anchor' => 'ok')).to eq('http://test.host/students/42/dummy_action/perform#ok') }
        end
      end

      describe '##{action}_path' do
        specify { expect(projector.confirm_path).to eq('/students/42/dummy_action/confirm') }
        specify { expect(projector.perform_path(bar: 'string')).to eq('/students/42/dummy_action/perform?bar=string') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_path('bar' => 'string')).to eq('/students/42/dummy_action/perform?bar=string') }
        end
      end
    end
  end

  describe 'controller testing' do
    projector { DummyAction.dummy }

    draw_routes do
      resources :students do
        granite 'dummy_action#dummy', on: :collection
      end
    end

    let(:response_json) { JSON.parse(response.body, symbolize_names: true) }

    [%i[get confirm], %i[post perform], %i[get custom], %i[post custom_post]].each do |method, action|
      it "successfully performs #{method} to #{action}" do
        public_send(method, action)
        expect(response).to be_successful
        expect(response_json).to eq(success: true, action: action.to_s)
      end
    end

    it 'passes extra params to the action' do
      get :confirm, params: {name: 'Test Name'}
      expect(projector.action).to have_attributes(name: 'Test Name')
    end
  end
end
