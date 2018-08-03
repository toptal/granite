RSpec.describe Granite::Action::TransactionManager do
  describe '.transaction' do
    shared_context 'handles transaction' do
      subject do
        described_class.transaction(trigger_callbacks_for: listener) do
          listener.perform
          described_class.transaction(trigger_callbacks_for: nested_listener) do
            nested_listener.perform
          end
        end
      end

      let(:listener) { double }
      let(:nested_listener) { double }

      it 'returns result of a block and triggers callbacks' do
        expect(listener).to receive(:perform).ordered
        expect(nested_listener).to receive(:perform).and_return(121).ordered
        expect(nested_listener).to receive(:run_callbacks).ordered
        expect(listener).to receive(:run_callbacks).ordered
        expect(subject).to eq 121
      end

      it 'does not trigger callbacks if block returns false' do
        expect(listener).to receive(:perform).ordered
        expect(nested_listener).to receive(:perform).and_return(false).ordered
        expect(subject).to eq false
      end

      context 'when block fails' do
        context 'with Granite::Action::Rollback' do
          context 'for parent' do
            it 'returns false and does not trigger nested transaction and callbacks' do
              expect(listener).to receive(:perform) { fail Granite::Action::Rollback }.ordered
              expect(subject).to eq false
            end
          end

          context 'for nested' do
            it 'returns false and does not trigger callbacks' do
              expect(listener).to receive(:perform).ordered
              expect(nested_listener).to receive(:perform) { fail Granite::Action::Rollback }.ordered
              expect(subject).to eq false
            end
          end
        end

        context 'with exception' do
          context 'for parent' do
            it 'raises error and does not trigger nested transacton and callbacks' do
              expect(listener).to receive(:perform) { fail 'I failed' }.ordered
              expect { subject }.to raise_error(RuntimeError, 'I failed')
            end
          end

          context 'for nested' do
            it 'raises error and does not trigger callbacks' do
              expect(listener).to receive(:perform).ordered
              expect(nested_listener).to receive(:perform) { fail 'I failed' }.ordered
              expect { subject }.to raise_error(RuntimeError, 'I failed')
            end
          end
        end
      end

      context 'when callback fails' do
        before do
          allow(listener).to receive(:perform)
          allow(nested_listener).to receive(:perform).and_return(121)
        end

        context 'for parent' do
          it 'runs nested callback and fails' do
            expect(nested_listener).to receive(:run_callbacks).ordered
            expect(listener).to receive(:run_callbacks) { fail 'I failed' }.ordered
            expect { subject }.to raise_error(RuntimeError, 'I failed')
          end
        end

        context 'for nested' do
          it 'runs parent callback and fails' do
            expect(nested_listener).to receive(:run_callbacks) { fail 'I failed' }.ordered
            expect(listener).to receive(:run_callbacks).ordered
            expect { subject }.to raise_error(RuntimeError, 'I failed')
          end
        end

        context 'for both' do
          it 'logs second failure and fails with the first' do
            expect(nested_listener).to receive(:run_callbacks) { fail 'I failed first' }.ordered
            expect(listener).to receive(:run_callbacks) { fail 'I failed second' }.ordered
            expect(ActiveData.config.logger).to receive(:error).with(/Unhandled.*RuntimeError.*I failed second.*\n.*transaction_manager_spec.*/)
            expect { subject }.to raise_error(RuntimeError, 'I failed first')
          end
        end
      end
    end

    context 'with ActiveRecord' do
      before do
        hide_const('ActiveRecord::Base')
        hide_const('ActiveRecord')
      end

      include_context 'handles transaction'
    end

    context 'without ActiveRecord' do
      include_context 'handles transaction'
    end
  end
end
