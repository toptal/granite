RSpec.describe Granite::Action::Policies do
  before do
    stub_class(:action, Granite::Action) do
      allow_if { performer.is_a?(Student) }

      private

      def execute_perform!(*)
      end
    end
  end

  describe '#perform' do
    specify { expect(Action.as(Student.new).new.perform).to eq(true) }
    specify do
      expect { Action.as(Teacher.new).new.perform }.to raise_error(
        Granite::Action::NotAllowedError,
        'Action action is not allowed for Teacher'
      )
    end

    context 'with performer.id' do
      let(:teacher) do
        Teacher.new.tap do |teacher|
          teacher.define_singleton_method(:id) { 24 }
        end
      end

      specify do
        expect { Action.as(teacher).new.perform }.to raise_error(
          Granite::Action::NotAllowedError,
          'Action action is not allowed for Teacher#24'
        )
      end
    end

    context 'with allow_self' do
      before do
        stub_class(:action, Granite::Action) do
          allow_self

          subject :student

          private

          def execute_perform!(*)
          end
        end
      end

      let(:student) { Student.new }

      specify { expect(Action.as(student).new(student).perform).to eq(true) }
      specify { expect { Action.as(Student.new).new(student).perform }.to raise_error Granite::Action::NotAllowedError }
      specify { expect { Action.as(Teacher.new).new(student).perform }.to raise_error Granite::Action::NotAllowedError }
    end
  end

  describe '#perform!' do
    specify { expect { Action.as(Student.new).new.perform! }.not_to raise_error }
    specify { expect { Action.as(Teacher.new).new.perform! }.to raise_error Granite::Action::NotAllowedError }
  end

  describe '#try_perform!' do
    before do
      stub_class(:action, Granite::Action) do
        allow_if { performer.is_a?(Student) }

        precondition do
          decline_with('error')
        end

        private

        def execute_perform!(*)
        end
      end
    end

    specify { expect { Action.as(Student.new).new.try_perform! }.not_to raise_error }
    specify { expect { Action.as(Teacher.new).new.try_perform! }.to raise_error Granite::Action::NotAllowedError }
  end

  describe 'default policies strategy' do
    it 'is AnyStrategy' do
      expect(Granite::Action._policies_strategy).to eq Granite::Action::Policies::AnyStrategy
    end
  end

  describe '#allowed?' do
    before do
      stub_class(:custom_strategy)
      stub_class(:action, Granite::Action) do
        self._policies_strategy = CustomStrategy
      end
    end
    let(:action) { Action.new }

    it 'delegates to policies_strategy' do
      allow(CustomStrategy).to receive(:allowed?).and_return('strategy_result')
      expect(action.allowed?).to eq 'strategy_result'
    end

    it 'memoizes result' do
      expect(CustomStrategy).to receive(:allowed?).once
      action.allowed?
      action.allowed?
    end
  end

  describe '#authorize!' do
    specify { expect { Action.as(Teacher.new).new.authorize! }.to raise_error Granite::Action::NotAllowedError }
  end
end
