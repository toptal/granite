RSpec.describe Granite::Action do
  before do
    stub_class(:action, Granite::Action) do
      allow_if { true }

      attribute :comment, String
    end
  end

  describe '.i18n_scope' do
    specify { expect(Action.i18n_scope).to eq :granite_action }
  end

  describe 'exception handling' do
    before do
      stub_class(:action, Granite::Action) do
        allow_if { true }

        attribute :email, String
        attribute :full_name, String

        validates :email, presence: true

        private

        def execute_perform!(*)
          errors.add(:email, 'custom error')
          DummyUser.new(attributes).validate!
        end
      end
    end

    let(:action) { Action.new(email: 'email') }

    describe 'active record' do
      before do
        stub_model_class 'DummyUser' do
          self.table_name = 'users'
          validates :email, format: /\A\w+@gmail.com\Z/
          validates :full_name, presence: true
        end
      end

      specify do
        expect { action.perform }.to change { action.errors.messages }
          .to(email: ['custom error', 'is invalid'], full_name: ["can't be blank"])
      end
    end

    describe 'active data' do
      before do
        stub_class 'DummyUser' do
          include ActiveData::Model
          attribute :email, String
          attribute :full_name, String

          validates :email, format: /\A\w+@gmail.com\Z/
          validates :full_name, presence: true
        end

        stub_class(:action, Granite::Action) do
          allow_if { true }

          attribute :email, String
          attribute :full_name, String

          validates :email, presence: true

          private

          def execute_perform!(*)
            errors.add(:email, 'custom error')
            DummyUser.new(attributes).validate!
          end
        end
      end

      specify do
        expect { action.perform }.to change { action.errors.messages }
          .to(email: ['custom error', 'is invalid'], full_name: ["can't be blank"])
      end
    end

    describe 'business action' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          attribute :email, String
          attribute :full_name, String

          validates :email, presence: true

          private

          def execute_perform!(*)
            errors.add(:email, 'custom error')
            NestedAction.new(attributes).perform!
          end
        end

        stub_class(:nested_action, Granite::Action) do
          allow_if { true }
          attribute :email, String
          attribute :full_name, String

          validates :email, format: /\A\w+@gmail.com\Z/
          validates :full_name, presence: true
        end
      end

      specify do
        expect { action.perform }.to change { action.errors.messages }
          .to(email: ['custom error', 'is invalid'], full_name: ["can't be blank"])
      end
    end
  end

  describe '#performable?' do
    before { Action.precondition { decline_with(:message) unless comment == 'Comment' } }

    specify { expect(Action.new(comment: 'Comment')).to be_performable }
    specify { expect(Action.new).not_to be_performable }
  end

  describe '#attributes_changed?' do
    before do
      stub_class(:action, Granite::Action) do
        subject :role
        attribute :name, String
      end
    end

    specify { expect(Action.new(role: Teacher.new)).not_to be_attributes_changed }
    specify { expect(Action.new(role: Teacher.new, name: 'Name')).to be_attributes_changed }
    specify { expect(Action.new(role: Teacher.new, name: 'Name')).not_to be_attributes_changed(except: 'name') }
  end

  describe 'nested attributes assigning' do
    subject { Action.new }

    before do
      allow(ActiveData.config.logger).to receive(:info)
    end

    specify do
      expect { subject.assign_attributes(action: {comment: 'Comment'}) }
        .to change { subject.comment }.to('Comment')
    end

    specify do
      expect { subject.assign_attributes('action' => {comment: 'Comment'}) }
        .to change { subject.comment }.to('Comment')
    end

    specify do
      expect { subject.assign_attributes(blabla: {comment: 'Comment'}) }
        .not_to change { subject.comment }
    end

    describe '#initialize' do
      specify { expect(Action.new(action: {comment: 'Comment'}).comment).to eq('Comment') }
    end

    describe '#update' do
      specify do
        expect { subject.update(action: {comment: 'Comment'}) }
          .to change { subject.comment }.to('Comment')
      end
    end
  end

  describe '#merge_errors' do
    subject(:action) { Action.new }

    let(:errors_to_merge) { ActiveModel::Errors.new(Action.new) }
    let(:error_args) { [] }
    let(:error_options) { {} }

    before { action.errors.add(*error_args, **error_options) }

    context 'when error types are string' do
      let(:error_args) { [:base, 'some error'] }

      context 'when errors have different attributes' do
        before { errors_to_merge.add(:comment, 'some error') }

        it 'merges given errors with existing ones' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['some error'], comment: ['some error'])
        end
      end

      context 'when errors have different types' do
        before { errors_to_merge.add(:base, 'some other error') }

        it 'merges given errors with existing ones' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['some error', 'some other error'])
        end
      end

      context 'when errors are duplicates' do
        before { errors_to_merge.add(:base, 'some error') }

        it 'does not duplicate existing errors' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['some error'])
        end
      end

      context 'when errors have options' do
        let(:error_args) { [:base, 'some error'] }
        let(:error_options) { {count: 1, message: 'count is wrong'} }

        context 'when message differs' do
          before { errors_to_merge.add(:base, 'some error', count: 1, message: 'count is low') }

          it 'does not duplicate existing errors' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['some error'])
          end
        end

        context 'when options differ' do
          before { errors_to_merge.add(:base, 'some error', count: 2, message: 'count is wrong') }

          it 'ignores options and does not duplicate existing errors' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['some error'])
          end
        end

        context 'when options match' do
          before { errors_to_merge.add(:base, 'some error', count: 1, message: 'count is wrong') }

          it 'does not duplicate existing errors' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['some error'])
          end
        end
      end
    end

    context 'when error types are symbol' do
      let(:error_args) { %i[base invalid] }

      context 'when errors have different attributes' do
        before { errors_to_merge.add(:comment, :invalid) }

        it 'merges given errors with existing ones' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['is invalid'], comment: ['is invalid'])
        end
      end

      context 'when errors have different types' do
        before { errors_to_merge.add(:base, :blank) }

        it 'merges given errors with existing ones' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['is invalid', 'can\'t be blank'])
        end
      end

      context 'when errors are duplicates' do
        before { errors_to_merge.add(:base, :invalid) }

        it 'does not duplicate existing errors' do
          action.merge_errors(errors_to_merge)

          expect(action.errors.messages).to match(base: ['is invalid'])
        end
      end

      context 'when errors have options' do
        let(:error_args) { %i[base invalid] }
        let(:error_options) { {count: 1, message: 'count is wrong'} }

        context 'when message differs' do
          before { errors_to_merge.add(:base, :invalid, count: 1, message: 'count is low') }

          it 'merges given errors with existing ones' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['count is wrong', 'count is low'])
          end
        end

        context 'when options differ' do
          before { errors_to_merge.add(:base, :invalid, count: 2, message: 'count is wrong') }

          it 'does not duplicate existing errors' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['count is wrong'])
          end
        end

        context 'when options match' do
          before { errors_to_merge.add(:base, :invalid, count: 1, message: 'count is wrong') }

          it 'does not duplicate existing errors' do
            action.merge_errors(errors_to_merge)

            expect(action.errors.messages).to match(base: ['count is wrong'])
          end
        end
      end
    end
  end
end
