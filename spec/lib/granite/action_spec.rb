RSpec.describe Granite::Action do
  before do
    stub_class(:action, Granite::Action) do
      allow_if { true }

      attribute :comment, String
    end
  end

  describe 'Dependency Injection' do
    before do
      stub_class(:action, Granite::Action) do
        allow_if { true }

        attribute :comment, String

        attr_reader :my_dep, :another_dep
        private :my_dep, :another_dep

        def initialize(*args, my_dep: Hash[a: 1], another_dep: 'Foo', **kwargs, &block)
          @my_dep = my_dep
          @another_dep = another_dep
          super(*args, **kwargs, &block)
        end
      end

      stub_class(:another_action, Granite::Action) do
        allow_if { true }
      end
    end

    it 'creates private getter' do
      action = Action.new(comment: 'blah blah blah')
      expect { action.my_dep }.to raise_error(NoMethodError, /private method `my_dep' called/)
    end

    it 'uses default value' do
      action = Action.new(comment: 'blah blah blah')
      expect(action.__send__(:my_dep)).to be_kind_of(Hash)
      expect(action.__send__(:another_dep)).to be_kind_of(String)
    end

    it 'uses custom value' do
      action = Action.new(comment: 'blah blah blah', my_dep: Array(1))
      expect(action.__send__(:my_dep)).to be_kind_of(Array)
    end

    it 'protects from mass assigment of attributes' do
      expect(ActiveData.config.logger).to receive(:info).with(/Ignoring undefined `foo` attribute value/)
      Action.new(foo: 'bar')
    end

    it 'does not assign dependencies to other actions' do
      another = AnotherAction.new
      expect { another.__send__(:my_dep) }.to raise_error(NoMethodError, /undefined method `my_dep'/)
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
