require 'rails_helper'

RSpec.describe User::Create do
  subject(:action) { described_class.as(performer).new(attributes) }

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
      expect { perform! }.to change { User.count }.by(1)
    end
  end
end
