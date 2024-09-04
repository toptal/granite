# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Boolean do
  describe 'typecasting' do
    include_context 'type setup', 'Boolean'

    specify { expect(typecast('hello')).to be_nil }
    specify { expect(typecast('true')).to eq(true) }
    specify { expect(typecast('false')).to eq(false) }
    specify { expect(typecast('1')).to eq(true) }
    specify { expect(typecast('0')).to eq(false) }
    specify { expect(typecast(true)).to eq(true) }
    specify { expect(typecast(false)).to eq(false) }
    specify { expect(typecast(1)).to eq(true) }
    specify { expect(typecast(0)).to eq(false) }
    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast([123])).to be_nil }
  end
end
