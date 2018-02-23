RSpec.describe 'raise_validation_error', aggregate_failures: false do
  before do
    stub_class(:action, Granite::Action) do
      allow_if { true }

      attribute :raise_error, Boolean

      handle_exception StandardError do |_error|
        decline_with(:some_error)
      end

      private def execute_perform!(*)
        fail StandardError if raise_error
      end
    end
  end

  context 'when action does not raise error' do
    let(:action) { Action.new }

    specify do
      expect { action.perform! }.not_to raise_validation_error
    end
  end

  context 'when action raises error' do
    let(:action) { Action.new(raise_error: true) }

    specify do
      expect do
        expect { action.perform! }.not_to raise_validation_error.of_type(:some_error)
      end.to fail_with('expected not to raise validation error on attribute :base of type :some_error')
    end

    specify do
      expect do
        expect { action.perform! }.to raise_validation_error.of_type(:some_error2)
      end.to fail_with('expected to raise validation error on attribute :base of type :some_error2, but raised {:base=>[{:error=>:some_error}]}')
    end

    specify do
      expect do
        expect { action.perform! }.to raise_validation_error.on_attribute(:raise_error)
      end.to fail_with('expected to raise validation error on attribute :raise_error, but raised {:base=>[{:error=>:some_error}], :raise_error=>[]}')
    end

    specify do
      expect do
        expect { action.perform! }.to raise_validation_error.on_attribute(:raise_error).of_type(:some_error)
      end.to fail_with('expected to raise validation error on attribute :raise_error of type :some_error, but raised {:base=>[{:error=>:some_error}], :raise_error=>[]}')
    end
  end
end
