# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Array do
  describe 'typecasting' do
    include_context 'type setup', 'Array'

    specify { expect(typecast([1, 2, 3])).to eq([1, 2, 3]) }
    specify { expect(typecast('hello, world')).to eq(%w[hello world]) }
    specify { expect(typecast(10)).to be_nil }
  end
end
