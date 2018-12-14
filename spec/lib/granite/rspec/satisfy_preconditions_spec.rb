RSpec.describe 'satisfy_preconditions', aggregate_failures: false do
  before do
    stub_class(:action, Granite::Action) do
      attribute :fail_precondition, Boolean
      attribute :second_fail_precondition, Boolean

      precondition do
        decline_with 'Precondition failed' if fail_precondition
        decline_with 'Multiple failures' if second_fail_precondition
      end
    end
  end

  context 'with no preconditions' do
    let(:action) { Action.new }

    specify { expect(action).to satisfy_preconditions }

    specify do
      expect do
        expect(action).not_to satisfy_preconditions
      end.to fail_with(%(expected #{action} not to satisfy preconditions but preconditions were satisfied))
    end
  end

  context 'with failing preconditions' do
    let(:action) { Action.new(fail_precondition: true) }

    specify { expect(action).not_to satisfy_preconditions.with_message('Precondition failed') }

    specify { expect(action).not_to satisfy_preconditions.with_message(/failed$/) }

    specify { expect(action).not_to satisfy_preconditions.with_message(a_string_starting_with('P')) }

    specify { expect(action).not_to satisfy_preconditions.with_messages('Precondition failed', /failed$/, /^Precondition/) }

    specify do
      expect do
        expect(action).to satisfy_preconditions
      end.to fail_with(%(expected #{action} to satisfy preconditions but got following errors:\n ["Precondition failed"]))
    end

    specify do
      expect do
        expect(action).not_to satisfy_preconditions.with_message('failed')
      end.to fail_with(%(expected #{action} not to satisfy preconditions with error messages ["failed"] but got following error messages:\n    ["Precondition failed"]))
    end

    specify do
      expect do
        expect(action).not_to satisfy_preconditions.with_messages(['WRONG TEXT'])
      end.to fail_with(%(expected #{action} not to satisfy preconditions with error messages ["WRONG TEXT"] but got following error messages:\n    ["Precondition failed"]))
    end

    specify do
      expect do
        expect(action).not_to satisfy_preconditions.with_messages(['WRONG TEXT']).exactly
      end.to fail_with(%(expected #{action} not to satisfy preconditions exactly with error messages ["WRONG TEXT"] but got following error messages:\n    ["Precondition failed"]))
    end

    specify do
      expect do
        expect(action).not_to satisfy_preconditions.with_messages_of_kinds(:custom_message, :custom_message2).exactly
      end.to fail_with(%(expected #{action} not to satisfy preconditions with error messages of kind [:custom_message, :custom_message2] but got following kind of error messages:\n    [:error]))
    end

    specify do
      expect do
        expect(action).not_to satisfy_preconditions.with_message_of_kind(:custom_message).exactly
      end.to fail_with(%(expected #{action} not to satisfy preconditions with error messages of kind [:custom_message] but got following kind of error messages:\n    [:error]))
    end
  end

  context 'with multiple failing preconditions' do
    let(:action) { Action.new(fail_precondition: true, second_fail_precondition: true) }

    specify { expect(action).not_to satisfy_preconditions.with_message('Precondition failed') }

    specify { expect(action).not_to satisfy_preconditions.with_message('Multiple failures') }

    context 'with `exactly`' do
      specify do
        expect do
          expect(action).not_to satisfy_preconditions.with_message('Precondition failed').exactly
        end.to fail_with(%(expected #{action} not to satisfy preconditions exactly with error messages ["Precondition failed"] but got following error messages:\n    ["Precondition failed", "Multiple failures"]))
      end

      specify { expect(action).not_to satisfy_preconditions.with_message(/failed|failures/).exactly }
    end
  end
end
