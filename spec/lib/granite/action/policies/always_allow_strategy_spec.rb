RSpec.describe Granite::Action::Policies::AlwaysAllowStrategy do
  describe '.allowed?' do
    subject { described_class.allowed?(action) }
    let(:action) { instance_double(Granite::Action) }

    it { is_expected.to be(true) }
  end
end
