RSpec.describe Granite::Action::TransactionManager do
  describe '.transaction' do
    subject do
      described_class.transaction do
        add_callbacks
        block
      end
    end

    shared_examples 'handles transaction' do
      let(:block) { 123 }

      let(:add_callbacks) do
        described_class.after_commit { block_listener.do_stuff }
        described_class.after_commit(object_listener)
      end

      let(:block_listener) { double(do_stuff: true) } # rubocop:disable RSpec/VerifiedDoubles
      let(:object_listener) { double(run_callbacks: true) } # rubocop:disable RSpec/VerifiedDoubles

      it 'returns result of a block and triggers registered callbacks' do
        expect(object_listener).to receive(:run_callbacks).with(:commit).ordered
        expect(block_listener).to receive(:do_stuff).ordered
        expect(subject).to eq 123
      end

      context 'with failed transaction' do
        let(:block) { fail 'I failed' }

        it 're-raise and doesnt run callbacks' do
          expect(object_listener).not_to receive(:run_callbacks)
          expect(block_listener).not_to receive(:do_stuff)
          expect { subject }.to raise_error(RuntimeError, 'I failed')
        end
      end

      context 'with nested transaction which fails' do
        let(:block) do
          described_class.after_commit(object_listener_one)
          described_class.transaction do
            described_class.after_commit(object_listener_two)
            fail 'I failed'
          end
        end

        let(:object_listener_one) { double(run_callbacks: true) } # rubocop:disable RSpec/VerifiedDoubles
        let(:object_listener_two) { double(run_callbacks: true) } # rubocop:disable RSpec/VerifiedDoubles

        specify 'both transactions reverted and error bubbled' do
          expect(object_listener).not_to receive(:run_callbacks)
          expect(block_listener).not_to receive(:do_stuff)
          expect(object_listener_one).not_to receive(:run_callbacks)
          expect(object_listener_two).not_to receive(:run_callbacks)
          expect { subject }.to raise_error(RuntimeError, 'I failed')
        end
      end

      context 'with failed after_commit callback' do
        let(:add_callbacks) do
          super()
          described_class.after_commit { fail 'callback failed' }
        end

        it 'calls for every callback and fails with first callback error' do
          expect(object_listener).to receive(:run_callbacks).with(:commit).ordered
          expect(block_listener).to receive(:do_stuff).ordered
          expect { subject }.to raise_error 'callback failed'
        end
      end

      context 'with multiple after_commit callbacks failures' do
        let(:add_callbacks) do
          super()
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
      include_examples 'handles transaction'

      context 'when transacton fails with Granite::Action::Rollback' do
        let(:block) { fail Granite::Action::Rollback }

        it 'returns false and does not trigger callbacks' do
          expect(object_listener).not_to receive(:run_callbacks)
          expect(block_listener).not_to receive(:do_stuff)
          expect(subject).to be(false)
        end
      end

      context 'with failing nested transaction' do
        let(:block) do
          described_class.after_commit(object_listener_one)
          User.new.save!
          described_class.transaction do
            described_class.after_commit(object_listener_two)
            Role.new.save!
            fail error
          end
          456
        end

        let(:object_listener_one) { double(run_callbacks: true) } # rubocop:disable RSpec/VerifiedDoubles
        let(:object_listener_two) { double(run_callbacks: true) } # rubocop:disable RSpec/VerifiedDoubles

        context 'with Granite::Action::Rollback' do
          let(:error) { Granite::Action::Rollback }

          specify 'only first transaction commited' do
            expect(object_listener).to receive(:run_callbacks)
            expect(block_listener).to receive(:do_stuff)
            expect(object_listener_one).to receive(:run_callbacks)
            expect(object_listener_two).not_to receive(:run_callbacks)
            expect do
              expect(subject).to eq 456
            end.to change { User.count }.by(1).and not_change { Role.count }
          end
        end

        context 'with any other error' do
          let(:error) { 'I failed' }

          specify 'no records created and error bubbled' do
            expect { subject }.to raise_error(RuntimeError, 'I failed')
              .and not_change { User.count }
              .and not_change { Role.count }
          end
        end
      end
    end

    context 'without ActiveRecord' do
      before do
        hide_const('ActiveRecord::Base')
        hide_const('ActiveRecord')
      end

      include_examples 'handles transaction'
    end
  end
end
