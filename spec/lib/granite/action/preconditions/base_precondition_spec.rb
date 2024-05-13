RSpec.describe Granite::Action::Preconditions::BasePrecondition do
  include_context 'with student data'

  let(:passed_student_action) { Action.new(subject: passed_student) }
  let(:failed_student_action) { Action.new(subject: failed_student) }

  context 'with simple declaration' do
    before do
      stub_class(:action, Granite::Action) do
        subject :student

        precondition do
          decline_with 'DECLINED' unless student.status == 'passed'
        end
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(passed_student_action).to satisfy_preconditions }
      specify { expect(failed_student_action).not_to satisfy_preconditions }
    end
  end

  context 'with :if option' do
    before do
      stub_class(:action, Granite::Action) do
        subject :student

        precondition if: -> { student.status == 'passed' } do
          decline_with 'DECLINED!'
        end
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(passed_student_action).not_to satisfy_preconditions }
      specify { expect(failed_student_action).to satisfy_preconditions }
    end
  end

  context 'with :unless option' do
    before do
      stub_class(:action, Granite::Action) do
        subject :student

        precondition unless: -> { student.status == 'passed' } do
          decline_with 'DECLINED!'
        end
      end
    end

    describe '#satisfy_preconditions?' do
      specify { expect(passed_student_action).to satisfy_preconditions }
      specify { expect(failed_student_action).not_to satisfy_preconditions }
    end
  end
end
