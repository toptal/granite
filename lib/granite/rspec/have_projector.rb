# @scope Business Actions
#
# Checks if the business action has the expected projector
#
# Example:
#
# ```ruby
# is_expected.to have_projector(:simple)
# ```
RSpec::Matchers.define :have_projector do |expected_projector|
  match do |action|
    @expected_projector = expected_projector
    @action_class = action.class
    @action_class._projectors.names.include?(expected_projector)
  end

  failure_message do
    "expected #{@action_class.name} to have a projector named #{@expected_projector}"
  end

  failure_message_when_negated do
    "expected #{@action_class.name} not to have a projector named #{@expected_projector}"
  end
end
