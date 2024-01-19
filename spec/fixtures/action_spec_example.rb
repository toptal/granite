require 'rails_helper'

RSpec.describe BA::User::Create do
  subject(:action) { described_class.as(performer).new(user, attributes) }

  let(:user) { User.new }
  let(:performer) { double }
  let(:attributes) { {} }

  describe 'policies' do
    it { is_expected.to be_allowed }

    context 'when user is not authorized' do
      it { is_expected.not_to be_allowed }
    end
  end

  describe 'preconditions' do
    it { is_expected.to satisfy_preconditions }

    context 'when preconditions fail' do
      it { is_expected.not_to satisfy_preconditions }
    end
  end

  describe 'validations' do
  end

  describe '#perform!' do
    specify do
      expect { perform!(user) }.to change { user.reload.attributes }.to(attributes)
    end
  end
end
