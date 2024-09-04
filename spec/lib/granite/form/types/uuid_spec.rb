# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::UUID do
  describe 'typecasting' do
    include_context 'type setup', 'Granite::Form::UUID'
    let(:uuid) { Granite::Form::UUID.random_create }
    let(:uuid_tools) { UUIDTools::UUID.random_create }

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast(Object.new)).to be_nil }
    specify { expect(typecast(uuid_tools)).to be_a Granite::Form::UUID }
    specify { expect(typecast(uuid_tools)).to eq(uuid_tools) }
    specify { expect(typecast(uuid)).to eq(uuid) }
    specify { expect(typecast(uuid.to_s)).to eq(uuid) }
    specify { expect(typecast(uuid.to_i)).to eq(uuid) }
    specify { expect(typecast(uuid.hexdigest)).to eq(uuid) }
    specify { expect(typecast(uuid.raw)).to eq(uuid) }
  end
end
