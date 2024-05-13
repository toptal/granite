RSpec.describe 'perform_action' do # rubocop:disable RSpec/DescribeClass
  let(:action) { DummyAction.new(user) }
  let(:other_action) { OtherAction.new }
  let(:user) { User.create! }
  let(:other_user) { User.create! }

  before do
    stub_class(:DummyAction, Granite::Action) do
      allow_if { true }
      subject :user

      def execute_perform!(*); end
    end

    stub_class(:OtherAction, Granite::Action) do
      allow_if { true }

      def execute_perform!(*); end
    end
  end

  it { expect { action.perform! }.to perform_action(DummyAction) }
  it { expect { other_action.perform! }.not_to perform_action(DummyAction) }

  describe 'failures' do
    it do
      expect do
        expect { action.perform! }.not_to perform_action(DummyAction)
      end.to fail_with('expected not to call DummyAction#perform!')
    end

    it do
      expect do
        expect { other_action.perform! }.to perform_action(DummyAction)
      end.to fail_with('expected to call DummyAction#perform!')
    end
  end

  describe '#using' do
    it { expect { action.try_perform! }.to perform_action(DummyAction).using(:try_perform!) }
    it { expect { action.perform }.to perform_action(DummyAction).using(:perform) }

    it do
      expect do
        expect { action.perform! }.to perform_action(DummyAction).using(:perform)
      end.to fail_with('expected to call DummyAction#perform')
    end
  end

  describe '#as' do
    it { expect { action.perform! }.to perform_action(DummyAction).as(nil) }

    it do # rubocop:disable RSpec/ExampleLength
      expect do
        expect { action.perform! }.to perform_action(DummyAction).as(user)
      end.to fail_with(<<~MESSAGE.strip)
        expected to call DummyAction#perform!
            AS #{user.inspect}
        received calls to DummyAction#perform!:
            AS nil
      MESSAGE
    end
  end

  describe '#with' do
    it { expect { action.perform! }.to perform_action(DummyAction).with(subject: user) }

    it { expect { action.perform! }.to perform_action(DummyAction).with(subject: kind_of(User)) }

    it do # rubocop:disable RSpec/ExampleLength
      expect do
        expect { action.perform! }.to perform_action(DummyAction).with(subject: other_user)
      end.to fail_with(<<~MESSAGE.strip)
        expected to call DummyAction#perform!
            WITH #{{ subject: other_user }.inspect}
        received calls to DummyAction#perform!:
            WITH #{{ subject: user }.inspect}
      MESSAGE
    end

    it do # rubocop:disable RSpec/ExampleLength
      kind_of_matcher = kind_of(String)
      expect do
        expect { action.perform! }.to perform_action(DummyAction).with(subject: kind_of_matcher)
      end.to fail_with(<<~MESSAGE.strip)
        expected to call DummyAction#perform!
            WITH #{{ subject: kind_of_matcher }.inspect}
        received calls to DummyAction#perform!:
            WITH #{{ subject: user }.inspect}
      MESSAGE
    end
  end
end
