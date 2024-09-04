require 'spec_helper'

RSpec.describe Granite::Form::Util do
  subject(:dummy) { Dummy.new('John') }

  before do
    stub_class(:dummy, Object) do
      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def full_name(last_name)
        [name, last_name].join(' ')
      end
    end

    Dummy.include described_class
  end

  describe '#evaluate' do
    subject { dummy.evaluate(target) }

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

    context 'with extra arguments' do
      subject { dummy.evaluate(target, 'Doe') }

      context 'when symbol is passed' do
        let(:target) { :full_name }

        it { is_expected.to eq('John Doe') }
      end

      context 'when lambda is passed' do
        let(:target) { ->(last_name) { ['John', last_name].join(' ') } }

        it { is_expected.to eq('John Doe') }
      end
    end
  end

  describe '#evaluate_if_proc' do
    subject { dummy.evaluate(target) }

    let(:target) { 'Peter' }

    it { is_expected.to eq('Peter') }

    context 'when lambda is passed' do
      let(:target) { -> { name } }

      it { is_expected.to eq('John') }
    end

    context 'with extra arguments' do
      subject { dummy.evaluate(target, 'Doe') }

      let(:target) { ->(last_name) { ['John', last_name].join(' ') } }

      it { is_expected.to eq('John Doe') }
    end
  end

  describe '#conditions_satisfied?' do
    subject { dummy.conditions_satisfied?(**conditions) }

    let(:conditions) { { if: -> { name == 'John' } } }

    it { is_expected.to be_truthy }

    context 'when if condition is satisfied' do
      before { dummy.name = 'Peter' }

      it { is_expected.to be_falsey }
    end

    context 'when unless condition is passed' do
      let(:conditions) { { unless: :name } }

      it { is_expected.to be_falsey }
    end

    context 'when no condition is passed' do
      let(:conditions) { {} }

      it { is_expected.to be_truthy }
    end

    context 'when both if & unless are passed' do
      let(:conditions) { { if: :name, unless: :name } }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
