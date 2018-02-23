module Granite::ActionHelpers
  extend ActiveSupport::Concern

  delegate :perform!, to: :subject
end

RSpec.configuration.define_derived_metadata(file_path: %r{spec/apq/actions/}) { |metadata| metadata[:type] ||= :granite_action }
RSpec.configuration.include Granite::ActionHelpers, type: :granite_action
