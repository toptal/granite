RSpec.describe Granite::Translations do
  before do
    stub_class(:test_action, Granite::Action) do
      attribute :id, Integer
    end
  end

  describe '.combine_paths' do
    def combine(*args)
      described_class.combine_paths(*args)
    end

    it do
      expect(combine(%w[long short], %w[name word])).to eq(%w[long.name long.word short.name short.word])
      expect(combine(['long', nil], %w[name])).to eq(%w[long.name name])
      expect(combine(%w[long], ['name', nil])).to eq(%w[long.name long])
    end
  end

  describe '.scope_translation_args' do
    def scope(*args, **options)
      described_class.scope_translation_args(TestAction.i18n_scopes, *args, **options)
    end

    it 'prepends translation key with action ancestor lookup scopes' do
      expect(scope('key')).to eq(['key', {default: []}])
      expect(scope(['key'])).to eq([['key'], {default: []}])
      expect(scope('key', default: ['Default'])).to eq(['key', {default: ['Default']}])
      expect(scope('key', default: 'Default')).to eq(['key', {default: ['Default']}])

      expect(scope('.key'))
        .to eq([:"granite_action.test_action.key", {default: %i[granite_action.granite/action.key key]}])
      expect(scope('.key', default: ['Default']))
        .to eq([:"granite_action.test_action.key", {default: [:'granite_action.granite/action.key', :key, 'Default']}])
    end
  end
end
