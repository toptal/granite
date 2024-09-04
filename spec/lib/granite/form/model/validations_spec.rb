require 'spec_helper'

RSpec.describe Granite::Form::Model::Validations do
  let!(:add_validations) { model.validates :name, presence: true }

  let(:model) do
    stub_model_granite_form(:model) do
      attribute :name, String
    end
  end

  before { add_validations }

  describe '.validates_nested?' do
    subject { model.validates_presence?(:name) }

    it { is_expected.to be_truthy }

    context 'when using string name' do
      subject { model.validates_presence?('name') }

      it { is_expected.to be_truthy }
    end

    context 'when attribute has no validations' do
      let(:add_validations) {}

      it { is_expected.to be_falsey }
    end

    context 'when attribute has different validations' do
      let(:add_validations) { model.validates :name, length: { maximum: 100 } }

      it { is_expected.to be_falsey }
    end
  end

  describe '#errors' do
    specify { expect(model.new.errors).to be_a ActiveModel::Errors }
    specify { expect(model.new.errors).to be_empty }
  end

  describe '#valid?' do
    specify { expect(model.new).not_to be_valid }
    specify { expect(model.new(name: 'Name')).to be_valid }
  end

  describe '#invalid?' do
    specify { expect(model.new).to be_invalid }
    specify { expect(model.new(name: 'Name')).not_to be_invalid }
  end

  describe '#validate!' do
    specify { expect { model.new.validate! }.to raise_error Granite::Form::ValidationError }
    specify { expect(model.new(name: 'Name').validate!).to eq(true) }
    specify { expect { model.new(name: 'Name').validate! }.not_to raise_error }
  end
end
