# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::String do
  describe 'typecasting' do
    include_context 'type setup', 'String'

    specify { expect(typecast('hello')).to eq('hello') }
    specify { expect(typecast(123)).to eq('123') }
    specify { expect(typecast(nil)).to be_nil }
  end
end
