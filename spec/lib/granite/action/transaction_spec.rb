RSpec.describe Granite::Action::Transaction do
  describe 'after_commit' do
    subject(:perform) { action.perform! }

    let(:action) { Action.new }

    before do
      stub_class(:action, Granite::Action) do
        allow_if { true }
        collection :callbacks, String

        after_commit do
          callbacks << 'after_commit'
        end

        def execute_perform!(*)
        end
      end
    end

    it { expect { perform }.to change { action.callbacks }.to(%w[after_commit]) }

    context 'when raises error' do
      before do
        stub_class(:dummy_error, StandardError)

        stub_class(:action, Granite::Action) do
          allow_if { true }

          after_commit do
            fail DummyError, 'Dummy exception'
          end
        end
      end

      context 'with unhandled error' do
        it 'fails' do
          expect(action).to receive(:execute_perform!)
          expect { subject }.to raise_error(DummyError, 'Dummy exception')
        end
      end

      context 'with an error which is handled by `handle_exception`' do
        before do
          Action.class_eval do
            handle_exception(DummyError) do |e|
              handle_dummy_error(e)
            end
          end
        end

        it 'does not fail' do
          expect(action).to receive(:execute_perform!)
          expect(action).to receive(:handle_dummy_error).with(instance_of(DummyError))
          subject
        end
      end
    end

    context 'when actions chained with after_commit' do
      let(:sub_action) { SubAction.new }

      before do
        stub_class(:dummy_error, StandardError)

        stub_class(:action, Granite::Action) do
          allow_if { true }

          after_commit do
            sub_action.perform!
          end
        end

        stub_class(:sub_action, Granite::Action) do
          allow_if { true }

          after_commit :after_commit_handler
        end

        allow(action).to receive(:sub_action).and_return(sub_action)
      end

      it do
        expect(action).to receive(:execute_perform!).ordered
        expect(sub_action).to receive(:execute_perform!).ordered
        expect(sub_action).to receive(:after_commit_handler).ordered
        subject
      end
    end
  end

  describe 'transaction' do
    subject { action.perform! }

    let(:action) { Action.new }

    before do
      stub_class(:action, Granite::Action) do
        allow_if { true }

        def execute_perform!(*)
          true
        end
      end
    end

    it 'opens a transaction and registers self as a callback' do
      expect(Granite::Action::TransactionManager).to receive(:transaction).ordered.and_call_original
      expect(Granite::Action::TransactionManager).to receive(:after_commit).ordered.with(action)
      subject
    end

    context 'with twice nested actions when the third action fails and the second silenced the failure' do
      before do
        stub_class(:action1, Granite::Action) do
          allow_if { true }

          def execute_perform!(*)
            User.new.save!
            Action2.new.perform
            User.new.save!
          end
        end

        stub_class(:action2, Granite::Action) do
          allow_if { true }

          def execute_perform!(*)
            Role.new.save!
            Action3.new.perform!
            Role.new.save!
          end
        end

        stub_class(:action3, Granite::Action) do
          allow_if { true }

          attribute :name, type: String
          validates :name, presence: true
        end
      end

      it 'commits changes of the first action only' do
        expect do
          expect(Action1.new.perform!).to be(true)
        end.to change { User.count }.by(2).and not_change { Role.count }
      end
    end
  end
end
