RSpec.describe 'have_projector', aggregate_failures: false do
  before do
    stub_class(:action, Granite::Action) do
      projector :simple
      projector :modal
    end
  end

  specify { expect(Action.new).to have_projector(:simple) }

  specify { expect(Action.new).to have_projector(:modal) }

  specify do
    expect do
      expect(Action.new).not_to have_projector(:modal)
    end.to fail_with 'expected Action not to have a projector named modal'
  end

  specify { expect(Action.new).not_to have_projector(:submit_form) }

  specify do
    expect do
      expect(Action.new).to have_projector(:submit_form)
    end.to fail_with 'expected Action to have a projector named submit_form'
  end
end
