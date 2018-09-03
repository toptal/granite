RSpec.describe Granite::Translations do
  subject(:action) { TestAction.new }
  before do
    stub_class(:test_action, Granite::Action) do
      attribute :id, Integer
    end
  end

  describe '#translate' do
    it { expect(subject.translate('key')).to eq('translation missing: en.key') }
    it { expect(subject.translate('.key')).to eq('translation missing: en.granite_action.test_action.key') }
  end

  describe '.scope_translation_args' do
    subject { action.class }

    it 'prepends translation key with action ancestor lookup scopes' do
      expect(subject.scope_translation_args(['key']))
        .to eq([:key,
                {default: []}])
    end

    it 'expands translation key if it is relative' do
      expect(subject.scope_translation_args(['.key']))
        .to eq([:"granite_action.test_action.key",
                {default: %i[granite_action.granite/action.key key]}])
    end
  end
end
