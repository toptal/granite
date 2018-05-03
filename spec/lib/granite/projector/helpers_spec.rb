RSpec.describe Granite::Projector::Helpers, type: :granite_projector do
  before do
    stub_class(:dummy_user)
    stub_class(:projector, Granite::Projector) do
      get :confirm, as: '' do
      end

      post :perform, as: '' do
      end

      get :result do
      end
    end
    stub_class(:dummy_action, Granite::Action) do
      projector :dummy, class_name: 'Projector'
    end
  end

  let(:action) { DummyAction.new }
  let(:projector) { DummyAction.dummy.new(action) }

  describe '#view_context' do
    let(:view_context) { Object.new }

    specify { expect(projector.view_context).to be_nil }
    specify { expect(Granite.with_view_context(view_context) { projector.view_context }).to eq(view_context) }
  end

  describe '#translate' do
    projector { DummyAction.dummy }

    specify do
      expect(controller.translate(:key)).to eq 'translation missing: en.key'
      expect(controller.view_context.translate(:key)).to eq '<span class="translation_missing" title="translation missing: en.key">Key</span>'
    end
  end

  context do
    projector { DummyAction.dummy }

    context 'without route' do
      describe '#action_url' do
        specify do
          expect do
            projector.action_url('confirm', foo: 'string')
          end.to raise_error(
            Granite::Projector::ActionNotMountedError,
            'Seems like DummyAction::DummyProjector was not mounted. Do you have dummy_action#dummy declared in routes?'
          )
        end
      end

      describe '#action_path' do
        specify do
          expect do
            projector.action_path('confirm')
          end.to raise_error(
            Granite::Projector::ActionNotMountedError,
            'Seems like DummyAction::DummyProjector was not mounted. Do you have dummy_action#dummy declared in routes?'
          )
        end
      end
    end

    context 'without subject' do
      draw_routes do
        resources :students, only: [] do
          granite 'dummy_action#dummy', on: :collection
        end
      end

      describe '#action_url' do
        specify { expect(projector.action_url('confirm', foo: 'string')).to eq('http://test.host/students/dummy_action?foo=string') }
        specify { expect(projector.action_url(:perform, anchor: 'ok')).to eq('http://test.host/students/dummy_action#ok') }
        specify { expect(projector.action_url(:result)).to eq('http://test.host/students/dummy_action/result') }
      end

      describe '#action_path' do
        specify { expect(projector.action_path('confirm')).to eq('/students/dummy_action') }
        specify { expect(projector.action_path(:perform, bar: 'string', only_path: false)).to eq('/students/dummy_action?bar=string') }
        specify { expect(projector.action_path(:result)).to eq('/students/dummy_action/result') }
      end
    end

    context 'with subject' do
      draw_routes do
        resources :students, only: [] do
          granite 'dummy_action#dummy', on: :member
        end
      end

      before do
        DummyAction.subject :role
        controller.params[:role] = Role.new(id: 42)
      end

      describe '#action_url' do
        specify { expect(projector.action_url('confirm', foo: 'string')).to eq('http://test.host/students/42/dummy_action?foo=string') }
        specify { expect(projector.action_url(:perform, anchor: 'ok')).to eq('http://test.host/students/42/dummy_action#ok') }
        specify { expect(projector.action_url(:result)).to eq('http://test.host/students/42/dummy_action/result') }
      end

      describe '#action_path' do
        specify { expect(projector.action_path('confirm')).to eq('/students/42/dummy_action') }
        specify { expect(projector.action_path(:perform, bar: 'string', only_path: false)).to eq('/students/42/dummy_action?bar=string') }
        specify { expect(projector.action_path(:result)).to eq('/students/42/dummy_action/result') }
      end
    end
  end
end
