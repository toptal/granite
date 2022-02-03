RSpec.describe Granite::Action::Subject do
  before do
    stub_class(:action, Granite::Action) do
      subject :student
      attribute :comment, String
    end
  end

  let(:student) { Student.create! }
  let(:teacher) { Teacher.create! }

  describe '#initialize' do
    specify { expect { Action.new(comment: 'Comment') }.to raise_error Granite::Action::SubjectNotFoundError }
    specify { expect(Action.new(comment: 'Comment', subject: student).student).to eq(student) }

    specify { expect { Action.new(nil, comment: 'Comment') }.to raise_error Granite::Action::SubjectNotFoundError }
    specify { expect { Action.new(nil, comment: 'Comment', subject: student) }.to raise_error Granite::Action::SubjectNotFoundError }

    specify { expect(Action.new(comment: 'Comment', id: student.id).student).to eq(student) }
    specify { expect { Action.new(comment: 'Comment', id: student.id.next) }.to raise_error Granite::Action::SubjectNotFoundError }

    specify { expect(Action.new(student, comment: 'Comment').student).to eq(student) }
    specify { expect(Action.new(student, comment: 'Comment', subject: nil).student).to eq(student) }

    specify { expect { Action.new(student.id, comment: 'Comment') }.to raise_error Granite::Action::SubjectTypeMismatchError }
    specify { expect { Action.new(student.id, comment: 'Comment', subject: nil) }.to raise_error Granite::Action::SubjectTypeMismatchError }

    specify { expect { Action.new(teacher, comment: 'Comment') }.to raise_error Granite::Action::SubjectTypeMismatchError }
    specify { expect { Action.new(teacher.id, comment: 'Comment') }.to raise_error Granite::Action::SubjectTypeMismatchError }
    specify { expect { Action.new(subject: teacher, comment: 'Comment') }.to raise_error Granite::Action::SubjectTypeMismatchError }

    specify { expect(Action.new(comment: 'Comment', subject: student).comment).to eq('Comment') }
    specify { expect(Action.new(student, comment: 'Comment').comment).to eq('Comment') }
  end
end
