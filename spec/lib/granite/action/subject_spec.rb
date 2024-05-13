RSpec.describe Granite::Action::Subject do
  let(:student) { Student.create! }
  let(:teacher) { Teacher.create! }

  describe '#initialize' do
    before do
      stub_class(:action, Granite::Action) do
        subject :student
        attribute :comment, String
      end
    end

    specify { expect { Action.new(comment: 'Comment') }.to raise_error Granite::Action::SubjectNotFoundError }
    specify { expect(Action.new(comment: 'Comment', subject: student).student).to eq(student) }

    specify { expect { Action.new(nil, comment: 'Comment') }.to raise_error Granite::Action::SubjectNotFoundError }

    specify do
      expect do
        Action.new(nil, comment: 'Comment', subject: student)
      end.to raise_error Granite::Action::SubjectNotFoundError
    end

    specify { expect(Action.new(comment: 'Comment', id: student.id).student).to eq(student) }

    specify do
      expect do
        Action.new(comment: 'Comment', id: student.id.next)
      end.to raise_error Granite::Action::SubjectNotFoundError
    end

    specify { expect(Action.new(student, comment: 'Comment').student).to eq(student) }
    specify { expect(Action.new(student, comment: 'Comment', subject: nil).student).to eq(student) }

    specify do
      expect do
        Action.new(student.id, comment: 'Comment')
      end.to raise_error Granite::Action::SubjectTypeMismatchError
    end

    specify do
      expect do
        Action.new(student.id, comment: 'Comment', subject: nil)
      end.to raise_error Granite::Action::SubjectTypeMismatchError
    end

    specify do
      expect do
        Action.new(teacher, comment: 'Comment')
      end.to raise_error Granite::Action::SubjectTypeMismatchError
    end

    specify do
      expect do
        Action.new(teacher.id, comment: 'Comment')
      end.to raise_error Granite::Action::SubjectTypeMismatchError
    end

    specify do
      expect do
        Action.new(subject: teacher, comment: 'Comment')
      end.to raise_error Granite::Action::SubjectTypeMismatchError
    end

    specify { expect(Action.new(comment: 'Comment', subject: student).comment).to eq('Comment') }
    specify { expect(Action.new(student, comment: 'Comment').comment).to eq('Comment') }
  end

  describe '.subject?' do
    before { stub_class(:action, Granite::Action) }

    specify { expect(Action).not_to be_subject }

    context 'when action defines subject' do
      before { Action.subject(:student) }

      specify { expect(Action).to be_subject }
    end
  end
end
