RSpec.describe Granite::Util do
  subject(:action) { DummyAction.new('John') }

  before do
    stub_class(:DummyAction, Object) do
      include Granite::Util

      attr_accessor :name

      def initialize(name)
        @name = name
      end
    end
  end

  describe '#evaluate' do
    subject { action.evaluate(target) }
    let(:target) { 'Peter' }

    it { is_expected.to eq('Peter') }

    context 'when symbol is passed' do
      let(:target) { :name }

      it { is_expected.to eq('John') }
    end

    context 'when lambda is passed' do
      let(:target) { -> { name } }

      it { is_expected.to eq('John') }
    end
  end

  describe '#conditions_satisfied?' do
    subject { action.conditions_satisfied?(**conditions) }
    let(:conditions) { {if: -> { name == 'John' }} }

    it { is_expected.to be_truthy }

    context 'when if condition is satisfied' do
      before { action.name = 'Peter' }

      it { is_expected.to be_falsey }
    end

    context 'when unless condition is passed' do
      let(:conditions) { {unless: :name} }

      it { is_expected.to be_falsey }
    end

    context 'when no condition is passed' do
      let(:conditions) { {} }

      it { is_expected.to be_truthy }
    end

    context 'when both if & unless are passed' do
      let(:conditions) { {if: :name, unless: :name} }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
