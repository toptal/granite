RSpec.describe Granite::Action::Policies::RequiredPerformerStrategy do
  describe '.allowed?' do
    subject { described_class.allowed?(action) }

    let(:action) { instance_double(Granite::Action, _policies: [proc { true }], performer: performer) }
    let(:performer) { nil }

    context 'when performer is present' do
      let(:performer) { 'performer' }

      it { is_expected.to be(true) }
    end

    context 'when performer is not persent' do
      it { is_expected.to be(false) }
    end
  end
end
