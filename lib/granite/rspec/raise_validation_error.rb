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

  chain :with_message do |message|
    @message = message
  end

  match do |block|
    begin
      block.call
      false
    rescue Granite::Action::ValidationError => e
      @details = e.errors.details

      @result =
        error_on_attribute?(e) &&
        error_type_matches?(e) &&
        message_matches?(e)
    end
  end

  description do
    expected = "raise validation error on attribute :#{@attribute || :base}"
    expected << " of type #{@error_type.inspect}" if @error_type
    expected << " with message #{@message.inspect}" if @message
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

  private

  def error_on_attribute?(e)
    e.errors.include?(@attribute || :base)
  end

  def error_type_matches?(e)
    return true unless @error_type
    details_being_checked = e.errors.details[@attribute || :base]
    details_being_checked&.any? { |x| x[:error] == @error_type }
  end

  def message_matches?(e)
    return true unless @message
    messages_being_checked = e.errors.messages[@attribute || :base]
    messages_being_checked&.include?(@message)
  end
end
