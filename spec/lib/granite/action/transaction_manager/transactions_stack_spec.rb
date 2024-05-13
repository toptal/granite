RSpec.describe Granite::Action::TransactionManager::TransactionsStack do
  subject(:transactions_stack) { described_class.new }

  let(:callback1) { double }

  it { expect(transactions_stack.depth).to eq(0) }

  it 'fails to add callback' do
    expect do
      transactions_stack.add_callback(callback1)
    end.to raise_error(RuntimeError, 'Start a transaction before you add callbacks on it')
  end

  context 'when in transaction' do
    let(:run_transaction) do
      transactions_stack.transaction do
        expect(transactions_stack.depth).to eq(1)
        expect { transactions_stack.add_callback(callback1) }.to change(transactions_stack, :callbacks).to([callback1])
        block1
      end
    end

    let(:block1) {} # rubocop:disable Lint/EmptyBlock

    it 'adds callbacks' do
      run_transaction
      expect(transactions_stack.callbacks).to eq([callback1])
    end

    context 'when failed with error' do
      let(:block1) { raise 'I failed' }

      it 're-raise error and doesnt store callbacks' do
        expect { run_transaction }.to raise_error(RuntimeError, 'I failed').and(not_change do
                                                                                  transactions_stack.callbacks
                                                                                end)
      end
    end

    context 'with a nested transaction inside' do
      let(:run_transaction) do
        transactions_stack.transaction do
          transactions_stack.add_callback(callback1)
          transactions_stack.transaction do
            expect(transactions_stack.depth).to eq(2)
            expect do
              transactions_stack.add_callback(callback2)
            end.to change(transactions_stack, :callbacks).to([callback1, callback2])
            block2
          end
        end
      end

      let(:block2) {} # rubocop:disable Lint/EmptyBlock
      let(:callback2) { double }

      it 'adds callbacks' do
        run_transaction
        expect(transactions_stack.callbacks).to eq([callback1, callback2])
      end

      context 'when failed' do
        let(:block2) { raise 'I failed' }

        it 're-raise error and doesnt store callbacks' do
          expect { run_transaction }.to raise_error(RuntimeError, 'I failed').and(not_change do
                                                                                    transactions_stack.callbacks
                                                                                  end)
        end
      end
    end
  end
end
