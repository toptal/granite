RSpec.describe Granite::Represents::Attribute do
  subject { action.attribute(:sign_in_count) }

  let(:action) { Action.new attributes }
  let(:attributes) { {} }

  before do
    stub_class(:dummy_user) do
      include ActiveData::Model

      attribute :sign_in_count, Integer, default: '1'
      attribute :created_at, Time
      attribute :has_signed_in, Boolean
    end

    stub_class(:action, Granite::Action) do
      allow_if { true }

      represents :sign_in_count, of: :user
      represents :created_at, default: -> { '2000-10-10' }, of: :user
      represents :has_signed_in, default: false, of: :user
      represents :related_ids, of: :user

      def user
        @user ||= DummyUser.new
      end
    end
  end

  describe '#initialize' do
    it 'sets default value' do
      expect(subject.read).to eq(1)
    end

    it 'sets default value_before_type_cast' do
      expect(subject.read_before_type_cast).to eq('1')
    end

    context 'when represented attribute has default value' do
      subject { action.attribute(:created_at) }

      it 'sets default value' do
        expect(subject.read).to eq Time.zone.parse('2000-10-10')
      end

      it 'sets default value_before_type_cast' do
        expect(subject.read_before_type_cast).to eq('2000-10-10')
      end

      context 'when model attribute present' do
        before do
          stub_class(:action, Granite::Action) do
            allow_if { true }

            represents :created_at, default: -> { '2000-10-10' }, of: :user

            def user
              @user ||= DummyUser.new(created_at: '2010-01-01')
            end
          end
        end

        it 'sets attribute value equal to model' do
          expect(subject.read).to eq Time.zone.parse('2010-01-01')
        end
      end
    end
  end

  describe '#sync' do
    specify do
      subject.write(2)
      expect { subject.sync }.to change { action.user.sign_in_count }.from(1).to(2)
    end

    context 'when represented object does not respond to attribute name' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          represents :sign_in_count, of: :user
          represents :related_ids, of: :user

          def user
            Object.new
          end
        end
      end

      specify do
        subject.write(2)
        expect { subject.sync }.not_to raise_error
      end
    end
  end

  describe '#typecast' do
    it 'returns original value when it has right class' do
      expect(subject.typecast(1)).to eq 1
    end

    it 'returns converted value to a proper type' do
      expect(subject.typecast('1')).to eq 1
    end

    it 'ignores nil' do
      expect(subject.typecast(nil)).to be_nil
    end
  end

  describe '#type' do
    context 'when defined in options' do
      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          represents :sign_in_count, of: :user, type: String

          def user
            @user ||= DummyUser.new
          end
        end
      end

      specify { expect(subject.type).to eq String }
    end

    context 'when defined in attribute' do
      before do
        stub_class(:dummy_user, Granite::Action) do
          attribute :sign_in_count, String
        end
      end

      specify { expect(subject.type).to eq String }
    end

    context 'when defined in references_many' do
      subject { action.attribute(:user_ids) }

      before do
        stub_model_class('DummyUser') do
          self.table_name = 'users'
        end

        stub_class(:holder) do
          include ActiveData::Model
          include ActiveData::Model::Associations

          references_many :users, class_name: 'User'
        end

        stub_class(:action, Granite::Action) do
          represents :user_ids, of: :holder

          def holder
            @holder ||= Holder.new
          end
        end
      end

      specify do
        expect(subject.type).to be_a Granite::Action::Types::Collection
        expect(subject.type.subtype).to eq Integer
      end
    end

    context 'when defined in collection' do
      subject { action.attribute(:users) }

      before do
        stub_class(:holder) do
          include ActiveData::Model
          include ActiveData::Model::Associations

          collection :users, String
        end

        stub_class(:action, Granite::Action) do
          represents :users, of: :holder

          def holder
            @holder ||= Holder.new
          end
        end
      end

      specify do
        expect(subject.type).to be_a Granite::Action::Types::Collection
        expect(subject.type.subtype).to eq String
      end
    end

    context 'when defined in dictionary' do
      subject { action.attribute(:numbers) }

      before do
        stub_class(:holder) do
          include ActiveData::Model
          include ActiveData::Model::Associations

          dictionary :numbers, Float
        end

        stub_class(:action, Granite::Action) do
          represents :numbers, of: :holder

          def holder
            @holder ||= Holder.new
          end
        end
      end

      specify do
        expect(subject.type).to be_a Granite::Action::Types::Collection
        expect(subject.type.subtype).to eq Float
      end
    end

    it 'derrives type from attribute of ActiveData::Model' do
      expect(subject.type).to eq Integer
    end

    context 'when defined in ActiveRecord::Base' do
      before do
        stub_model_class('DummyUser') do
          self.table_name = 'users'
        end
      end

      context 'with usual attribute' do
        specify do
          expect(subject.type).to eq Integer
        end
      end

      context 'with array' do
        subject { action.attribute(:related_ids) }

        specify do
          expect(subject.type).to be_a Granite::Action::Types::Collection
          expect(subject.type.subtype).to eq Integer
        end
      end
    end

    context 'when not defined' do
      before { stub_class(:dummy_user) }

      specify { expect(subject.type).to eq Object }
    end
  end

  describe '#typecaster' do
    specify do
      expect(subject.typecaster).to eq ActiveData.typecaster(Integer)
    end
  end

  describe 'changed?' do
    context 'when attribute has not default value' do
      specify do
        expect(subject.owner.user).to_not receive(:sign_in_count)
        expect(subject.owner).to receive(:sign_in_count_changed?)
        expect(subject).not_to be_changed
      end
    end

    context 'when attribute has default value' do
      subject { action.attribute(:created_at) }

      specify do
        expect(subject.owner.user).to receive(:created_at)
        expect(subject.owner).not_to receive(:created_at_changed?)
        expect(subject).to be_changed
      end
    end

    context 'when attribute has false as default value' do
      subject { action.attribute(:has_signed_in) }

      specify do
        expect(subject.owner.user).to receive(:has_signed_in)
        expect(subject.owner).not_to receive(:has_signed_in_changed?)
        expect(subject).to be_changed
      end
    end
  end
end
