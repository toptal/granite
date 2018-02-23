RSpec.describe Granite::Action::Policies::AnyStrategy do
  describe '.allowed?' do
    subject { described_class.allowed?(action) }
    let(:action) { instance_double('Granite::Action', _policies: policies, performer: nil) }
    let(:policies) { [] }

    context 'when action has no policies defined' do
      it { is_expected.to eq false }
    end

    context 'when action has at least one "true" policy' do
      let(:policies) { [proc { false }, proc { true }, proc { false }] }
      it { is_expected.to eq true }
    end

    context 'when action has all policies evaled to true' do
      let(:policies) { [proc { true }, proc { true }] }
      it { is_expected.to eq true }
    end

    context 'when action has all policies evaled to false' do
      let(:policies) { [proc { false }, proc { false }] }
      it { is_expected.to eq false }
    end
  end
end
