RSpec.describe Granite::Action::Transaction do
  describe 'after_commit' do
    subject { action.perform! }

    let(:action) { Action.new }

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

      context 'which is unhandled' do
        before do
          class Action
          end
        end

        it 'fails' do
          expect(action).to receive(:execute_perform!)
          expect{subject}.to raise_error(DummyError, 'Dummy exception')
        end
      end

      context 'which is handled by `handle_exception`' do
        before do
          class Action
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
  end
end
