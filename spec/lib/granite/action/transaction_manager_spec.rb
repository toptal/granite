RSpec.describe Granite::Action::TransactionManager do
  describe '.transaction' do
    shared_examples 'handles transaction' do
      subject do
        described_class.transaction do
          123
        end
      end

      let(:block_listener) { double(do_stuff: true) }
      let(:object_listener) { double(run_callbacks: true) }

      before do
        described_class.after_commit { block_listener.do_stuff }
        described_class.after_commit(object_listener)
      end


      it 'returns result of a block and triggers registered callbacks' do
        expect(object_listener).to receive(:run_callbacks).with(:commit).ordered
        expect(block_listener).to receive(:do_stuff).ordered
        expect(subject).to eq 123
      end

      context 'when transaction fails' do
        subject do
          described_class.transaction do
            false
          end
        end

        it 'returns result of a block and does not trigger registered callbacks' do
          expect(object_listener).not_to receive(:run_callbacks)
          expect(block_listener).not_to receive(:do_stuff)
          expect(subject).to eq false
        end


        context 'with Granite::Action::Rollback' do
          subject do
            described_class.transaction do
              fail Granite::Action::Rollback
            end
          end

          it 'returns false and does not trigger callbacks' do
            expect(object_listener).not_to receive(:run_callbacks)
            expect(block_listener).not_to receive(:do_stuff)
            expect(subject).to eq false
          end
        end

        context 'with StandardError' do
          subject do
            described_class.transaction do
              fail 'I failed'
            end
          end

          it 'fails and doesnt run callbacks' do
            expect(object_listener).not_to receive(:run_callbacks)
            expect(block_listener).not_to receive(:do_stuff)
            expect { subject }.to raise_error(RuntimeError, 'I failed')
          end
        end
      end

      context 'with nested transaction' do
        subject do
          described_class.transaction do
            described_class.transaction do
              fail 'I failed'
            end
            456
          end
        end

        it 'does not run callbacks if child transaction failed' do
          expect(object_listener).not_to receive(:run_callbacks)
          expect(block_listener).not_to receive(:do_stuff)
          expect { subject }.to raise_error(RuntimeError, 'I failed')
        end
      end

      context 'when callback fails' do
        before do
          described_class.after_commit { fail 'callback failed' }
        end

        it 'calls for every callback and fails with first callback error' do
          expect(object_listener).to receive(:run_callbacks).with(:commit).ordered
          expect(block_listener).to receive(:do_stuff).ordered
          expect { subject }.to raise_error 'callback failed'
        end
      end

      context 'when multiple callbacks fail' do
        before do
          described_class.after_commit { fail 'callback failed second' }
          described_class.after_commit { fail 'callback failed first' }
        end

        it 'calls for every callback, fails with first callback error and logs others' do
          expect(object_listener).to receive(:run_callbacks).with(:commit).ordered
          expect(block_listener).to receive(:do_stuff).ordered
          expect(ActiveData.config.logger).to receive(:error).with(/Unhandled.*RuntimeError.*callback failed second.*\n.*transaction_manager_spec.*/)
          expect { subject }.to raise_error 'callback failed first'
        end
      end
    end

    context 'with ActiveRecord' do
      before do
        hide_const('ActiveRecord::Base')
        hide_const('ActiveRecord')
      end

      include_examples 'handles transaction'
    end

    context 'without ActiveRecord' do
      include_examples 'handles transaction'
    end
  end
end
