RSpec.describe Granite::Projector::ControllerActions, type: :granite_projector do
  before do
    stub_class(:projector, Granite::Projector) do
      get :confirm do
      end

      post :perform do
      end

      get :custom, as: '' do
      end

      post :custom_post, as: '' do
      end
    end
    stub_class(:descendant, Projector)
    stub_class(:action, Granite::Action) do
      projector :dummy, class_name: 'Projector'
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
    specify { expect(Projector.action_for(:get, 'perform')).to eq nil }
    specify { expect(Projector.action_for(:get, '')).to eq :custom }
    specify { expect(Projector.action_for(:post, '')).to eq :custom_post }

    context 'with custom name' do
      before do
        stub_class(:projector, Granite::Projector) do
          get(:confirm, as: 'test') {}
        end
      end

      specify { expect(Projector.action_for(:get, 'confirm')).to eq nil }
      specify { expect(Projector.action_for(:get, 'test')).to eq :confirm }
    end
  end

  describe 'projector related' do
    projector { Action.dummy }

    context 'with no subject' do
      draw_routes do
        resources :students do
          granite 'action#dummy', on: :collection
        end
      end

      describe '##{action}_url' do
        specify { expect(projector.confirm_url(foo: 'string')).to eq('http://test.host/students/action/confirm?foo=string') }
        specify { expect(projector.perform_url(anchor: 'ok')).to eq('http://test.host/students/action/perform#ok') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_url('anchor' => 'ok')).to eq('http://test.host/students/action/perform#ok') }
        end
      end

      describe '##{action}_path' do
        specify { expect(projector.confirm_path).to eq('/students/action/confirm') }
        specify { expect(projector.perform_path(bar: 'string')).to eq('/students/action/perform?bar=string') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_path('bar' => 'string')).to eq('/students/action/perform?bar=string') }
        end
      end
    end

    context 'with subject' do
      draw_routes do
        resources :students do
          granite 'action#dummy', on: :member
        end
      end

      before do
        Action.subject :role
        controller.params[:role] = Role.new(id: 42)
      end

      describe '##{action}_url' do
        specify { expect(projector.confirm_url(foo: 'string')).to eq('http://test.host/students/42/action/confirm?foo=string') }
        specify { expect(projector.perform_url(anchor: 'ok')).to eq('http://test.host/students/42/action/perform#ok') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_url('anchor' => 'ok')).to eq('http://test.host/students/42/action/perform#ok') }
        end
      end

      describe '##{action}_path' do
        specify { expect(projector.confirm_path).to eq('/students/42/action/confirm') }
        specify { expect(projector.perform_path(bar: 'string')).to eq('/students/42/action/perform?bar=string') }

        context 'with option keys provides as strings' do
          specify { expect(projector.perform_path('bar' => 'string')).to eq('/students/42/action/perform?bar=string') }
        end
      end
    end
  end
end
