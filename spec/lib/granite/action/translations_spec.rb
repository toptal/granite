RSpec.describe Granite::Action::Translations do
  before do
    stub_class(:dummy_action, Granite::Action) do
      attribute :id, Integer
    end
  end

  describe '.i18n_scope' do
    subject { DummyAction.i18n_scope }

    it { is_expected.to eq(:granite_action) }
  end

  describe '.i18n_scopes' do
    subject { DummyAction.i18n_scopes }

    it { is_expected.to eq([:"granite_action.dummy_action", :"granite_action.granite/action", nil]) }
  end

  describe '.translate' do
    subject { DummyAction.new.t('.key') }

    it { is_expected.to eq('dummy action key') }
  end
end
