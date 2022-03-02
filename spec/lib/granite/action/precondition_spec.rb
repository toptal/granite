RSpec.describe Granite::Action::Precondition do
  before do
    stub_class(:test_precondition, described_class) do
      description 'Test description'

      def call(expected_title:, **)
        expected_title == title
      end
    end

    stub_class(:action, Granite::Action) do
      attribute :title, String
    end
  end

  describe '.description' do
    specify { expect(TestPrecondition.description).to eq('Test description') }
  end

  describe '#call' do
    let(:action) { Action.new(title: 'Ruby') }
    let(:precondition) { TestPrecondition.new(action) }

    specify do
      expect(action).to receive(:title).and_call_original

      expect(precondition.call(expected_title: 'Ruby')).to be(true)
    end
  end
end
