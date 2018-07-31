RSpec.describe Granite::Action::Transaction do
  describe '.handle_exception' do
    let(:action) { Action.new }

    before do
      stub_class(:dummy_error, StandardError)
      stub_class(:action, Granite::Action) do
        allow_if { true }

        after_commit do
          fail DummyError, 'Dummy exception'
        end

        handle_exception(DummyError) do |e|
          handle_dummy_error(e)
        end
      end
    end

    specify do
      expect(action).to receive(:execute_perform!)
      expect(action).to receive(:handle_dummy_error).with(instance_of(DummyError))
      action.perform!
    end
  end

  describe '#transaction' do
    shared_context 'handles transaction' do
      subject { action.perform(block: block, nested_action_block: nested_action_block) }

      let(:action) { Action.new }
      let(:call_chain) { [] }
      let(:block) { ->{} }
      let(:nested_action_block) { ->{} }

      before do
        stub_class(:action, Granite::Action) do
          allow_if { true }

          after_commit do
            call_chain << 'action_after_commit'
          end

          private

          def execute_perform!(block:, nested_action_block:)
            call_chain << 'action_perform'
            block.call
            NestedAction.new.perform!(block: nested_action_block)
          end
        end

        stub_class(:nested_action, Granite::Action) do
          allow_if { true }

          after_commit do
            call_chain << 'nested_action_after_commit'
          end

          private

          def execute_perform!(block:)
            call_chain << 'nested_action_perform'
            block.call
          end
        end

        allow_any_instance_of(Action).to receive(:call_chain).and_return(call_chain)
        allow_any_instance_of(NestedAction).to receive(:call_chain).and_return(call_chain)
      end

      context 'and without exceptions' do
        let(:nested_action_block) { -> { 121 } }

        specify do
          expect(subject).to eq 121
          expect(call_chain).to eq %w[action_perform nested_action_perform nested_action_after_commit action_after_commit]
        end
      end

      context 'when raises Granite::Action::Rollback' do
        shared_context 'raises Granite::Action::Rollback' do
          let(:klass) do
            stub_class(:data) do
              include ActiveData::Model
              attribute :name, String
              validates :name, presence: true
            end
          end

          specify do
            expect(subject).to eq false
            expect(call_chain).to eq expected_call_chain
          end
        end

        context 'by a parent action' do
          let(:block) { -> { klass.new.validate! } }
          let(:expected_call_chain) { %w[action_perform] }

          include_context 'raises Granite::Action::Rollback'
        end

        context 'by a nested action' do
          let(:nested_action_block) { -> { klass.new.validate! } }
          let(:expected_call_chain) {  %w[action_perform nested_action_perform]}

          include_context 'raises Granite::Action::Rollback'
        end
      end

      context 'when raises exception' do
        shared_context 'raises exception' do
          specify do
            expect { subject }.to raise_error(RuntimeError, 'I failed')
            expect(call_chain).to eq expected_call_chain
          end
        end

        context 'by a parent action' do
          let(:block) { -> { fail 'I failed' } }
          let(:expected_call_chain) { %w[action_perform] }

          include_context 'raises exception'
        end

        context 'by a nested action' do
          let(:nested_action_block) { -> { fail 'I failed' } }
          let(:expected_call_chain) { %w[action_perform nested_action_perform] }

          include_context 'raises exception'
        end
      end

      context 'when callback fails' do
        context 'for parent action' do
          before do
            class Action
              after_commit do
                fail 'after_commit failed'
              end
            end
          end

          specify do
            expect { subject }.to raise_error(RuntimeError, 'after_commit failed')
            expect(call_chain).to eq %w[action_perform nested_action_perform nested_action_after_commit]
          end
        end

        context 'for nested action action' do
          before do
            class NestedAction
              after_commit do
                fail 'after_commit failed'
              end
            end
          end

          specify do
            expect { subject }.to raise_error(RuntimeError, 'after_commit failed')
            expect(call_chain).to eq %w[action_perform nested_action_perform action_after_commit]
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
