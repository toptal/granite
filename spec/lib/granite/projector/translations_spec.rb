RSpec.describe Granite::Projector::Translations do
  before do
    stub_class(:projector, Granite::Projector) do
      get :new do
      end

      post :create do
      end
    end

    stub_class(:test_action, Granite::Action) do
      projector :dummy, class_name: 'Projector'

      attribute :id, Integer
    end
  end

  subject(:projector) { TestAction.new.dummy }

  describe '#translate' do
    it { expect(subject.translate('key')).to eq('<span class="translation_missing" title="translation missing: en.key">Key</span>') }
    it { expect(subject.translate('.key')).to eq('<span class="translation_missing" title="translation missing: en.dummy.key">Key</span>') }
  end

  describe '.scope_translation_args_by_projector' do
    subject { projector.class }

    it 'prepends translation key with action ancestor lookup scopes' do
      expect(subject.scope_translation_args_by_projector(['key']))
        .to eq([:key,
                {default: []}])
    end

    it 'expands translation key if it is relative' do
      expect(subject.scope_translation_args_by_projector(['.key']))
        .to eq([:"granite_action.test_action.dummy.key",
                {default: %i[granite_action.granite/action.dummy.key dummy.key]}])
    end

    it 'injects projector action name into keys if present' do
      expect(subject.scope_translation_args_by_projector(['.key'], action_name: :new))
        .to eq([:"granite_action.test_action.dummy.new.key",
                {default: %i[granite_action.test_action.dummy.key
                             granite_action.granite/action.dummy.new.key
                             granite_action.granite/action.dummy.key
                             dummy.new.key dummy.key]}])
    end
  end
end
