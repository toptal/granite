RSpec.describe Granite::Action::Preconditions::EmbeddedPrecondition do
  include_context 'with student data'

  before do
    stub_class(:embedded_action, Granite::Action) do
      subject :student
      precondition { decline_with(:embedded_not_passed) unless student.status == 'passed' }
    end

    stub_class(:action, Granite::Action) do
      subject :student
      precondition embedded: :embedded_action

      def embedded_action
        EmbeddedAction.new(student)
      end
    end
  end

  describe '#satisfy_preconditions?' do
    specify { expect(Action.new(subject: passed_student)).to satisfy_preconditions }

    context 'with a failed embedded preconditions' do
      subject(:action) { Action.new(subject: failed_student) }

      let(:error) { action.errors.first }

      specify do
        expect(action)
          .not_to satisfy_preconditions.with_message('Embedded Not Passed')

        expect(error.type).to eq :embedded_not_passed
      end
    end

    context 'with :if' do
      before do
        stub_class(:action, Granite::Action) do
          subject :student
          precondition embedded: :embedded_action, if: -> { false }
        end
      end

      specify { expect(Action.new(subject: failed_student)).to satisfy_preconditions }
    end

    context 'with :unless' do
      before do
        stub_class(:action, Granite::Action) do
          subject :student
          precondition embedded: :embedded_action, unless: -> { true }
        end
      end

      specify { expect(Action.new(subject: failed_student)).to satisfy_preconditions }
    end
  end
end
