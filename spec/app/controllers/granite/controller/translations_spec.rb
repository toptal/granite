RSpec.describe Granite::Controller::Translations, type: :granite_projector do
  prepend_before do
    stub_class(:dummy_projector, Granite::Projector)
    stub_class(:dummy_action, Granite::Action) do
      projector :dummy
    end
  end

  projector { DummyAction.dummy }

  describe '#i18n_scopes' do
    it do
      expect(controller.i18n_scopes).to eq %w[granite_action.dummy_action.dummy granite_action.granite/action.dummy dummy]
    end

    context 'when action name is :result' do
      before { controller.action_name = :result }

      it do
        expect(controller.i18n_scopes).to eq %w[granite_action.dummy_action.dummy.result granite_action.dummy_action.dummy granite_action.granite/action.dummy.result granite_action.granite/action.dummy dummy.result dummy]
      end
    end
  end

  describe '#translate' do
    it do
      expect(controller.translate('.key')).to eq 'dummy action dummy projector key'
      expect(controller.translate('.other_key')).to eq 'dummy projector other key'
      expect(controller.view_context.translate('.key')).to eq 'dummy action dummy projector key'

      expect(controller.view_context.translate(:no_such_key)).to eq '<span class="translation_missing" title="translation missing: en.no_such_key">No Such Key</span>'
    end

    context 'when action name is :result' do
      before { controller.action_name = :result }

      it do
        expect(controller.translate('.key')).to eq 'dummy action dummy projector result key'
        expect(controller.view_context.translate('.key')).to eq 'dummy action dummy projector result key'
      end
    end
  end
end
