RSpec.describe Granite::Action::Performing do
  before do
    allow(I18n.exception_handler).to receive(:raise_translation_exception?).and_return(false)

    stub_model_class 'DummyUser' do
      self.table_name = 'users'
      validates :email, presence: true
    end

    stub_class(:action, Granite::Action) do
      allow_if { true }

      attribute :login, String

      precondition { decline_with(:message) if login == '' }

      validates :login, format: /\A\w+\z/, on: :user

      subject :user, class_name: 'DummyUser'

      embeds_many :skills do
        primary :name, String
        attribute :name, String
        validates :name, presence: true
      end
      accepts_nested_attributes_for :skills

      private

      def execute_perform!(number: 42)
        subject.email = login
        subject.save!
        number
      end
    end
  end

  let(:user) { DummyUser.create!(email: 'Email') }

  describe '.handle_exception' do
    before do
      stub_class(:dummy_error, StandardError)
      stub_class(:action, Granite::Action) do
        allow_if { true }

        handle_exception StandardError do |e|
          errors.add :base, e.message
        end

        references_one :user, class_name: 'DummyUser'

        attribute :login, String

        private

        def execute_perform!(*)
          user.email = login
          user.save!
          fail DummyError, 'Dummy exception'
        end
      end
    end

    let(:action) { Action.new(user: user, login: 'Login') }

    specify do
      expect { expect(action.perform).to be(false) }
        .to change { action.errors.messages }.to(base: ['Dummy exception'])
        .and not_change { user.reload.email }
    end

    specify { expect(action.perform(some_value: 'value')).to be(false) }

    specify do
      expect { action.perform! }
        .to raise_error(Granite::Action::ValidationError) { |error| expect(error.backtrace[0]).to include('spec/lib/granite/action/performing_spec.rb') }
        .and change { action.errors.messages }.to(base: ['Dummy exception'])
        .and not_change { user.reload.email }
    end

    specify { expect { action.perform!(some_value: 'value') }.to raise_error(Granite::Action::ValidationError) { |error| expect(error.backtrace[0]).to include('spec/lib/granite/action/performing_spec.rb') } }
  end

  describe '.perform' do
    let(:action_definition) do
      stub_class(:action, Granite::Action) do
        perform do
        end
      end
    end

    specify do
      expect { action_definition }.to raise_error('Perform block declaration was removed! Please declare `private def execute_perform!(*)` method')
    end
  end

  describe '#perform' do
    context 'with login' do
      let(:action) { Action.new(user, login: 'Login') }

      specify { expect(action.perform).to eq(42) }
      specify { expect(action.perform(number: 43)).to eq(43) }
      specify { expect { action.perform }.to change { user.reload.email }.to('Login') }
    end

    context 'with nested attributes' do
      let(:action) { Action.new(user, login: 'Login', skills_attributes: [{name: ''}]) }

      before do
        allow(Granite::Form.config.logger).to receive(:info)
      end

      specify { expect(action.perform).to be(false) }
      specify { expect { action.perform }.to change { action.errors.messages }.to('skills.0.name': ["can't be blank"]) }
      specify { expect { action.perform }.not_to change { user.reload.email } }
    end

    context 'without login' do
      let(:action) { Action.new(user) }

      specify { expect(action.perform).to be(false) }
      specify { expect { action.perform }.to change { action.errors.messages }.to(email: ["can't be blank"]) }
      specify { expect { action.perform }.not_to change { user.reload.email } }
    end

    context 'with empty login' do
      let(:action) { Action.new(user, login: '') }

      specify { expect(action.perform).to be(false) }
      specify { expect { action.perform }.to change { action.errors.messages }.to(base: ['Base error message']) }
      specify { expect { action.perform }.not_to change { user.reload.email } }
    end

    context 'without policies' do
      before { stub_class(:action, Granite::Action) { allow_if { true } } }

      specify { expect { Action.new.perform }.to raise_error NotImplementedError }
    end

    context 'when execute_perform! returns false' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          private

          def execute_perform!(*)
            false
          end
        end
      end

      let(:action) { Action.new }
      specify { expect(action.perform).to be(true) }
    end

    describe 'validation contexts' do
      context 'with :user context' do
        subject { action.perform(context: :user) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          it { is_expected.to eq(42) }
          specify { expect(action.perform(context: :user, number: 43)).to eq(43) }
          specify { expect { subject }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          it { is_expected.to be(false) }
          specify { expect { subject }.to change { action.errors.messages }.to(login: ['is invalid']) }
          specify { expect { subject }.not_to change { user.reload.email } }
        end
      end

      context 'with :admin context' do
        subject { action.perform(context: :admin) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          it { is_expected.to eq(42) }
          specify { expect { subject }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          it { is_expected.to eq(42) }
          specify { expect { subject }.to change { user.reload.email }.to('Foo Bar') }
        end
      end
    end
  end

  describe '#perform!' do
    context 'with login' do
      let(:action) { Action.new(user, login: 'Login') }

      specify { expect(action.perform!).to eq(42) }
      specify { expect(action.perform!(number: 43)).to eq(43) }
      specify { expect { action.perform! }.to change { user.reload.email }.to('Login') }
    end

    context 'with nested attributes' do
      let(:action) { Action.new(user, login: 'Login', skills_attributes: [{name: ''}]) }

      before do
        allow(Granite::Form.config.logger).to receive(:info)
      end

      specify do
        expect { action.perform! }
          .to raise_error(Granite::Action::ValidationError)
          .and change { action.errors.messages }.to('skills.0.name': ["can't be blank"])
          .and not_change { user.reload.email }
      end
    end

    context 'without login' do
      let(:action) { Action.new(user) }

      specify do
        expect { action.perform! }
          .to raise_error(Granite::Action::ValidationError)
          .and change { action.errors.messages }.to(email: ["can't be blank"])
          .and not_change { user.reload.email }
      end
    end

    context 'with empty login' do
      let(:action) { Action.new(user, login: '') }

      specify do
        expect { action.perform! }
          .to raise_error(Granite::Action::ValidationError)
          .and change { action.errors.messages }.to(base: ['Base error message'])
          .and not_change { user.reload.email }
      end
    end

    context 'without policies' do
      before { stub_class(:action, Granite::Action) { allow_if { true } } }

      specify { expect { Action.new.perform! }.to raise_error NotImplementedError }
    end

    context 'when execute_perform! returns false' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          private

          def execute_perform!(*)
            false
          end
        end
      end

      let(:action) { Action.new }
      specify { expect(action.perform!).to be(true) }
    end

    describe 'validation contexts' do
      context 'with :user context' do
        subject { action.perform!(context: :user) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          it { is_expected.to eq(42) }
          specify { expect(action.perform!(context: :user, number: 43)).to eq(43) }
          specify { expect { subject }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          specify do
            expect { subject }
              .to raise_error(Granite::Action::ValidationError)
              .and change { action.errors.messages }.to(login: ['is invalid'])
              .and not_change { user.reload.email }
          end
        end
      end

      context 'with :admin context' do
        subject { action.perform!(context: :admin) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          specify { expect(action.perform!(context: :admin)).to eq(42) }
          specify { expect { action.perform!(context: :admin) }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          specify { expect(action.perform!(context: :admin)).to eq(42) }
          specify { expect { action.perform!(context: :admin) }.to change { user.reload.email }.to('Foo Bar') }
        end
      end
    end
  end

  describe '#try_perform!' do
    context 'with login' do
      let(:action) { Action.new(user, login: 'Login') }

      specify { expect(action.try_perform!).to eq(42) }
      specify { expect(action.try_perform!(number: 43)).to eq(43) }
      specify { expect { action.try_perform! }.to change { user.reload.email }.to('Login') }
    end

    context 'with nested attributes' do
      let(:action) { Action.new(user, login: 'Login', skills_attributes: [{name: ''}]) }

      before do
        allow(Granite::Form.config.logger).to receive(:info)
      end

      specify do
        expect { action.try_perform! }
          .to raise_error(Granite::Action::ValidationError)
          .and change { action.errors.messages }.to('skills.0.name': ["can't be blank"])
          .and not_change { user.reload.email }
      end
    end

    context 'without login' do
      let(:action) { Action.new(user) }

      specify do
        expect { action.try_perform! }
          .to raise_error(Granite::Action::ValidationError)
          .and change { action.errors.messages }.to(email: ["can't be blank"])
          .and not_change { user.reload.email }
      end
    end

    context 'with empty login' do
      let(:action) { Action.new(user, login: '') }

      specify { expect { action.try_perform! }.not_to raise_error }
      specify { expect { action.try_perform! }.to change { action.errors.messages }.to(base: ['Base error message']) }
      specify { expect { action.try_perform! }.not_to change { user.reload.email } }
    end

    context 'without policies' do
      before { stub_class(:action, Granite::Action) { allow_if { true } } }

      specify { expect { Action.new.try_perform! }.to raise_error NotImplementedError }
    end

    context 'when execute_perform! returns false' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          private

          def execute_perform!(*)
            false
          end
        end
      end

      let(:action) { Action.new }
      specify { expect(action.try_perform!).to be(true) }
    end

    context 'when transaction is called only once' do
      before do
        Action.class_eval do
          attr_reader :variable

          def transaction
            @variable ||= 0
            @variable += 1
            super
          end
        end
      end

      let(:action) { Action.new(user, login: 'Login') }

      specify { expect { action.try_perform! }.to change { action.variable }.to(1) }

      specify do
        expect do
          action.try_perform!
          action.try_perform!
        end.to change { action.variable }.to(2)
      end
    end

    describe 'validation contexts' do
      context 'with :user context' do
        subject { action.try_perform!(context: :user) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          it { is_expected.to eq(42) }
          specify { expect(action.try_perform!(context: :user, number: 43)).to eq(43) }
          specify { expect { subject }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          specify do
            expect { subject }
              .to raise_error(Granite::Action::ValidationError)
              .and change { action.errors.messages }.to(login: ['is invalid'])
              .and not_change { user.reload.email }
          end
        end
      end

      context 'with :admin context' do
        subject { action.try_perform!(context: :admin) }

        context 'with valid data in all contexts' do
          let(:action) { Action.new(user, login: 'Login') }

          it { is_expected.to eq(42) }
          specify { expect { subject }.to change { user.reload.email }.to('Login') }
        end

        context 'with invalid data for the :user context' do
          let(:action) { Action.new(user, login: 'Foo Bar') }

          it { is_expected.to eq(42) }
          specify { expect { subject }.to change { user.reload.email }.to('Foo Bar') }
        end
      end
    end
  end

  describe '#performed?' do
    before do
      stub_class(:action, Granite::Action) do
        allow_if { true }

        subject :user, class_name: 'DummyUser'

        precondition { decline_with(:message) if trigger_precondition_failure }

        attribute :trigger_precondition_failure, Boolean

        private

        def execute_perform!(*)
        end
      end
    end

    it 'is false if perform was not called' do
      expect(Action.new(user)).not_to be_performed
    end

    it 'is true if performed ws called successfully' do
      action = Action.new(user)
      expect { action.perform }.to change { action.performed? }.to(true)
    end

    it 'is false if perform failed precondition' do
      action = Action.new(user, trigger_precondition_failure: true)
      expect { action.perform }.not_to change { action.performed? }.from(false)
    end
  end
end
