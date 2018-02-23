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
          .to(email: ['is invalid'], full_name: ["can't be blank"])
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
      end

      specify do
        expect { action.perform }.to change { action.errors.messages }
          .to(email: ['is invalid'], full_name: ["can't be blank"])
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
          .to(email: ['is invalid'], full_name: ["can't be blank"])
      end
    end
  end

  describe '#performable?' do
    before { Action.precondition { decline_with(:message) unless comment == 'Comment' } }

    specify { expect(Action.new(comment: 'Comment')).to be_performable }
    specify { expect(Action.new).not_to be_performable }
  end

  describe '#attributes_changed??' do
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
end
