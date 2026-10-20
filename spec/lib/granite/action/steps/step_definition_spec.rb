RSpec.describe Granite::Action::Steps::StepDefinition do
  subject(:definition) { described_class.new(AssignName, **options) }

  let(:options) { {} }
  let(:performer) { User.new(full_name: 'Master Performer') }

  before do
    stub_class 'AssignName', Granite::Action do
      attribute :name, String
      references_one :user
    end

    stub_class 'UpdateUser', Granite::Action do
      def user
        @user ||= User.new
      end
    end
  end

  describe '#to_step' do
    subject(:to_step) { definition.to_step(action, name: 'The Rock', user: nil) }

    let(:action) { UpdateUser.as(performer).new }

    it { is_expected.to have_attributes(performer:, name: 'The Rock', user: nil) }

    context 'when step has a subject' do
      before { AssignName.subject :user }

      it { is_expected.to have_attributes(performer:, name: 'The Rock', subject: action.user) }
    end

    context 'when definition has additional attributes' do
      let(:options) { { attributes: { user: :performer } } }

      it { is_expected.to have_attributes(name: 'The Rock', user: performer) }
    end
  end

  describe '#perform_with' do
    subject { definition.perform_with }

    it { is_expected.to eq(:perform!) }

    context 'when not required' do
      let(:options) { { required: false } }

      it { is_expected.to eq(:try_perform!) }
    end
  end
end
