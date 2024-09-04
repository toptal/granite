# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Float do
  describe 'typecasting' do
    include_context 'type setup', 'Float'

    specify { expect(typecast('hello')).to be_nil }
    specify { expect(typecast('123hello')).to be_nil }
    specify { expect(typecast('123')).to eq(123.0) }
    specify { expect(typecast('123.')).to be_nil }
    specify { expect(typecast('123.5')).to eq(123.5) }
    specify { expect(typecast(123)).to eq(123.0) }
    specify { expect(typecast(123.5)).to eq(123.5) }
    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast([123.5])).to be_nil }
  end
end
