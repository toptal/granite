RSpec::Matchers.define :perform_action do |klass|
  chain :using do |using|
    @using = using
  end

  chain :as do |performer|
    @performer = performer
  end

  chain :with do |attributes|
    @attributes = attributes
  end

  match do |block|
    @klass = klass
    @using ||= :perform!

    @payloads = []
    subscriber = ActiveSupport::Notifications.subscribe('granite.perform_action') do |_, _, _, _, payload|
      @payloads << payload
    end

    block.call

    ActiveSupport::Notifications.unsubscribe(subscriber)

    @payloads.detect { |payload| action_matches?(payload[:action]) && payload[:using] == @using }
  end

  failure_message do
    output = "expected to call #{performed_entity}"
    add_performer_message(output, @performer) if defined?(@performer)
    add_attributes_message(output, @attributes) if defined?(@attributes)

    similar_payloads = @payloads.select { |payload| class_matches?(payload[:action]) && payload[:using] == @using }
    if similar_payloads.present?
      output << "\nreceived calls to #{performed_entity}:"
      similar_payloads.each { |payload| add_message_from_payload(output, payload) }
    end

    output
  end

  failure_message_when_negated do
    "expected not to call #{performed_entity}"
  end

  supports_block_expectations

  private

  def add_message_from_payload(output, payload)
    action = payload[:action]
    add_performer_message(output, action.performer) if defined?(@performer)
    add_attributes_message(output, actual_attributes(action)) if defined?(@attributes)
  end

  def add_performer_message(output, performer)
    output << "\n    AS #{performer.inspect}"
  end

  def add_attributes_message(output, attributes)
    output << "\n    WITH #{attributes.inspect}"
  end

  def performed_entity
    "#{@klass}##{@using}"
  end

  def actual_attributes(action)
    @attributes.keys.to_h { |attr| [attr, action.public_send(attr)] }
  end

  def action_matches?(action)
    class_matches?(action) && performer_matches?(action) && attributes_match?(action)
  end

  def class_matches?(action)
    action.is_a?(@klass)
  end

  def performer_matches?(action)
    !defined?(@performer) || action.performer == @performer
  end

  def attributes_match?(action)
    !defined?(@attributes) || match(@attributes).matches?(actual_attributes(action))
  end
end
