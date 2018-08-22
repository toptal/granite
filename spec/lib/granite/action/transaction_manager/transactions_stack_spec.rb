RSpec.describe Granite::Action::TransactionManager::TransactionsStack do
  let(:callback1) { double }

  it { expect(subject.depth).to eq(0) }

  it 'fails to add callback' do
    expect { subject.add_callback(callback1) }.to raise_error(RuntimeError, 'Start a transaction before you add callbacks on it')
  end

  context 'when in transaction' do
    let(:run_transaction) do
      subject.transaction do
        expect(subject.depth).to eq(1)
        expect { subject.add_callback(callback1) }.to change { subject.callbacks }.to([callback1])
        block1
      end
    end

    let(:block1) {}

    it 'adds callbacks' do
      run_transaction
      expect(subject.callbacks).to eq([callback1])
    end

    context 'and failed with error' do
      let(:block1) { fail 'I failed' }

      it 're-raise error and doesnt store callbacks' do
        expect { run_transaction }.to raise_error(RuntimeError, 'I failed').and not_change { subject.callbacks }
      end
    end

    context 'with a nested transaction inside' do
      let(:run_transaction) do
        subject.transaction do
          subject.add_callback(callback1)
          subject.transaction do
            expect(subject.depth).to eq(2)
            expect { subject.add_callback(callback2) }.to change { subject.callbacks }.to([callback1, callback2])
            block2
          end
        end
      end

      let(:block2) {}
      let(:callback2) { double }

      it 'adds callbacks' do
        run_transaction
        expect(subject.callbacks).to eq([callback1, callback2])
      end

      context 'which failed' do
        let(:block2) { fail 'I failed' }

        it 're-raise error and doesnt store callbacks' do
          expect { run_transaction }.to raise_error(RuntimeError, 'I failed').and not_change { subject.callbacks }
        end
      end
    end
  end
end
