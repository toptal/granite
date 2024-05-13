module Granite
  module ActionHelpers # :nodoc:
    extend ActiveSupport::Concern

    delegate :perform!, to: :subject
  end
end

RSpec.configuration.define_derived_metadata(file_path: %r{spec/apq/actions/}) do |metadata|
  metadata[:type] ||= :granite_action
end
RSpec.configuration.include Granite::ActionHelpers, type: :granite_action
