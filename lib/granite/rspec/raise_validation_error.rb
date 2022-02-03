# @scope BusinessActions
#
# Checks if code in block raises `Granite::Action::ValidationError`.
#
# Modifiers:
# * `on_attribute(attribute)` -- error relates to attribute specified;
# * `of_type` -- checks the error has a message with the specified symbol;
#
# Examples:
#
# ```ruby
# expect { code }.to raise_validation_error.of_type(:some_error_key)
# expect { code }.to raise_validation_error.on_attribute(:skill_sets).of_type(:some_other_key)
# ```
#
RSpec::Matchers.define :raise_validation_error do
  chain :on_attribute do |attribute|
    @attribute = attribute
  end

  chain :of_type do |error_type|
    @error_type = error_type
  end

  match do |block|
    block.call
    false
  rescue Granite::Action::ValidationError => e
    @details = e.errors.details
    @details_being_checked = @details[@attribute || :base]
    @result = @details_being_checked&.any? { |x| x[:error] == @error_type }
  end

  description do
    expected = "raise validation error on attribute :#{@attribute || :base}"
    expected << " of type #{@error_type.inspect}" if @error_type
    expected << ", but raised #{@details.inspect}" unless @result
    expected
  end

  failure_message do
    "expected to #{description}"
  end

  failure_message_when_negated do
    "expected not to #{description}"
  end

  supports_block_expectations
end
