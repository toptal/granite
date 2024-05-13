RSpec.describe Granite::Projector::Translations, type: :granite_projector do
  prepend_before do
    stub_class(:dummy_projector, Granite::Projector)
    stub_class(:dummy_action, Granite::Action) do
      projector :dummy
    end
  end

  projector { DummyAction.dummy }

  describe '#i18n_scopes' do
    it do
      expect(projector.i18n_scopes).to eq %w[granite_action.dummy_action.dummy granite_action.granite/action.dummy
                                             dummy]
    end
  end

  describe '#translate' do
    it do
      expect(projector.translate('.key')).to eq 'dummy action dummy projector key'
      expect(projector.translate('.other_key')).to eq 'dummy projector other key'
      expect(projector.translate(:no_such_key))
        .to eq '<span class="translation_missing" title="translation missing: en.no_such_key">No Such Key</span>'
    end
  end
end
