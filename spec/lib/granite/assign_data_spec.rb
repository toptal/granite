RSpec.describe Granite::AssignData do
  subject(:action) { DummyAction.new(user) }
  let!(:user) { User.create! }

  before do
    stub_class(:dummy_action, Granite::Action) do
      subject :user
    end
  end

  context 'when using block with assign data' do
    before do
      DummyAction.assign_data do
        user.full_name = 'New Name'
      end
    end

    it { expect { action.validate }.to change { user.full_name }.to('New Name') }
  end

  context 'when using method name with assign data' do
    before do
      DummyAction.class_eval do
        assign_data :set_name

        def set_name
          user.full_name = 'New Name'
        end
      end
    end

    it { expect { action.validate }.to change { user.full_name }.to('New Name') }
  end

  context 'when using method name & options' do
    before do
      DummyAction.class_eval do
        assign_data :set_name, if: -> { user.full_name.blank? }

        def set_name
          user.full_name = 'New Name'
        end
      end
    end

    it { expect { action.validate }.to change { user.full_name }.to('New Name') }

    context 'when conditions are not satisfied' do
      let!(:user) { User.create! full_name: 'Existing name' }

      it { expect { action.validate }.not_to change { user.full_name } }
    end
  end
end
