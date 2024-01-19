RSpec.describe Granite::Action::Types::Collection do
  subject { described_class.new(subtype) }
  let(:subtype) { 'some_type' }

  describe '#subtype' do
    its(:subtype) { is_expected.to eq subtype }
  end
end
