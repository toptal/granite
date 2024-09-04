# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::UUID do
  subject(:uuid) { Granite::Form::UUID.random_create }

  specify { expect(uuid.as_json).to eq(uuid.to_s) }
  specify { expect(uuid.to_json).to eq("\"#{uuid}\"") }
  specify { expect(uuid.to_param).to eq(uuid.to_s) }
  specify { expect(uuid.to_query(:key)).to eq("key=#{uuid}") }
end
