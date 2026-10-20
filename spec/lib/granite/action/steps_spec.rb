RSpec.describe Granite::Action::Steps do
  delegate :perform!, to: :action

  subject(:action) { UpdateUser.as(performer).new(user, **attributes) }

  let(:performer) { User.new(full_name: 'Master Performer') }
  let(:user) { User.new }
  let(:attributes) { {} }

  before do
    stub_class('StepsAction', Granite::Action) do |context|
      include context.described_class
      prepend Granite::Action::AssignAttributes

      allow_if { true }
    end

    stub_class('UpdateUser', StepsAction) do
      subject :user
    end
  end

  context 'when subject is nil' do
    let(:user) { nil }

    specify do
      expect { perform! }.to raise_error(Granite::Action::SubjectNotFoundError)
        .with_message('Unable to initialize UpdateUser without subject provided')
    end
  end

  context 'when subject is a null object' do
    before do
      stub_model_class('NullUser', User) do
        define_method(:nil?) { true }
      end
    end

    let(:user) { NullUser.new }

    specify do
      expect { perform! }.to raise_error(Granite::Action::SubjectNotFoundError)
        .with_message('Unable to initialize UpdateUser without subject provided')
    end
  end

  context 'when subject has mismatched class' do
    let(:user) { User }

    specify do
      expect { perform! }.to raise_error(Granite::Action::SubjectTypeMismatchError)
        .with_message('Unable to initialize UpdateUser with Class as subject, expecting instance of User')
    end
  end

  describe '.step' do
    let(:assign_name_options) { {} }
    let(:assign_name_block) { nil }

    before do
      stub_class('AssignName', StepsAction) do
        subject :user

        assign_data :assign_name
        def assign_name
          user.full_name = 'The Rock'
        end
      end

      UpdateUser.step :assign_name, AssignName, **assign_name_options, &assign_name_block
    end

    it { expect { perform! }.to change(user, :full_name).to('The Rock') }

    context 'when there are multiple steps' do
      before do
        stub_class('AddCatchphrase', StepsAction) do
          subject :user

          assign_data do
            user.full_name = "If you smell what #{user.full_name} is cooking"
          end
        end

        UpdateUser.step :add_catchphrase, AddCatchphrase
      end

      it { expect { perform! }.to change(user, :full_name).to('If you smell what The Rock is cooking') }
    end

    context 'when step requires attributes' do
      let(:attributes) { { full_name: 'Dwayne Johnson' } }

      before do
        AssignName.class_eval do
          represents :full_name, of: :subject

          def assign_name; end
        end
      end

      it { expect { perform! }.to change(user, :full_name).to('Dwayne Johnson') }

      context 'when attributes are nested under parent action' do
        let(:attributes) { { UpdateUser.model_name.param_key.to_sym => super() } }

        it { expect { perform! }.to change(user, :full_name).to('Dwayne Johnson') }
      end
    end

    context 'when step depends on performer' do
      before do
        AssignName.class_eval do
          def assign_name
            user.full_name = performer.full_name
          end
        end
      end

      it { expect { perform! }.to change(user, :full_name).to('Master Performer') }
    end

    context 'when step has failing preconditions' do
      before do
        AssignName.class_eval do
          precondition { decline_with :invalid }
        end
      end

      it do
        expect(action).not_to satisfy_preconditions
        expect(action.errors.to_hash).to eq(base: ['is invalid'])
      end
    end

    context 'when step is invalid' do
      let(:attributes) { { full_name: '' } }

      before do
        AssignName.class_eval do
          attribute :full_name, String
          validates :full_name, presence: true
        end
      end

      it do
        expect(action).not_to be_valid
        expect(action.errors.to_hash).to eq(full_name: ["can't be blank"])
      end
    end

    context 'with inline step' do
      before do
        UpdateUser.class_eval do
          attribute :inline_called, Boolean, default: false
          inline_step(:add_catchphrase) { self.inline_called = true }
        end
      end

      it { expect { perform! }.to change(action, :inline_called).to(true) }
      it { expect(action.add_catchphrase.failed_preconditions).to be_empty }
    end

    context 'when extending the step class' do
      let(:assign_name_block) do
        proc do
          def assign_name
            super
            user.full_name = "If you smell what #{user.full_name} is cooking"
          end
        end
      end

      it { expect { perform! }.to change(user, :full_name).to('If you smell what The Rock is cooking') }
    end

    context 'when using conditions' do
      let(:attributes) { { name_assigned: false } }
      let(:assign_name_options) { { if: :name_assigned } }

      before do
        UpdateUser.attribute :name_assigned, Boolean

        AssignName.class_eval do
          attribute :name_assigned, Boolean
          precondition { decline_with(:invalid) unless name_assigned }
          validate { errors.add(:name_assigned, :invalid) unless name_assigned }
        end
      end

      it { expect { perform! }.not_to change(user, :full_name) }

      context 'when name_assigned is true' do
        let(:attributes) { { name_assigned: true } }

        it { expect { perform! }.to change(user, :full_name).to('The Rock') }
      end
    end

    context 'when using conditions with inline step' do
      let(:attributes) { { censor_name: false } }

      before do
        UpdateUser.class_eval do
          attribute :censor_name, Boolean
          inline_step :censor, if: :censor_name do
            user.full_name = '[Censored]'
          end
        end
      end

      it { expect { perform! }.to change(user, :full_name).to('The Rock') }

      context 'when censor_name is true' do
        let(:attributes) { { censor_name: true } }

        it { expect { perform! }.to change(user, :full_name).to('[Censored]') }
      end
    end

    context 'when step is optional' do
      let(:assign_name_options) { { required: false } }

      it do
        expect do
          expect(action).to satisfy_preconditions
          expect(action).to be_valid
          perform!
        end.to change(user, :full_name).to('The Rock')
      end

      context 'when step has failing preconditions' do
        before { AssignName.precondition { decline_with :invalid } }

        it do
          expect do
            expect(action).to satisfy_preconditions
            expect(action).to be_valid
            perform!
          end.not_to change(user, :full_name)
        end
      end

      context 'when step has failing validations' do
        before { AssignName.validate { errors.add :base, :invalid } }

        it do
          expect(action).to satisfy_preconditions
          expect(action).to be_valid
          expect { perform! }.to raise_error(Granite::Action::ValidationError)
        end
      end
    end

    context 'when step uses local preconditions' do
      let(:assign_name_options) { { required: :no_nested_preconditions } }

      it do
        expect do
          expect(action).to satisfy_preconditions
          expect(action).to be_valid
          perform!
        end.to change(user, :full_name).to('The Rock')
      end

      context 'when step has failing preconditions' do
        before { AssignName.precondition { decline_with :invalid } }

        it do
          expect(action).to satisfy_preconditions
          expect(action).not_to be_valid
          expect { perform! }.to raise_error(Granite::Action::ValidationError)
        end
      end

      context 'when step has failing validations' do
        before { AssignName.validate { errors.add :base, :invalid } }

        it do
          expect(action).to satisfy_preconditions
          expect(action).not_to be_valid
          expect { perform! }.to raise_error(Granite::Action::ValidationError)
        end
      end
    end

    context 'when step sets data for main action' do
      before do
        UpdateUser.validate { errors.add :base, :invalid if user.full_name.blank? }
      end

      it { expect(action).to be_valid }
    end

    context 'when subject of another step depends on previous step' do
      before do
        stub_class(:UpdateNewUser, StepsAction) do
          subject :new_user, class_name: 'User'

          private

          def execute_perform!(*)
            new_user.full_name = 'New User'
          end
        end

        AssignName.class_eval do
          def new_user
            @new_user ||= User.new(full_name: 'NEEDS UPDATE')
          end
        end

        UpdateUser.class_eval do
          delegate :new_user, to: :assign_name
          step :update_new_user, UpdateNewUser
        end
      end

      it { expect { perform! }.to change(action.assign_name.new_user, :full_name).to('New User') }
    end
  end
end
