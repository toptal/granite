# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Date do
  describe 'typecasting' do
    include_context 'type setup', 'Date'
    let(:date) { Date.new(2013, 6, 13) }

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast('2013-06-13')).to eq(date) }
    specify { expect(typecast('2013-55-55')).to be_nil }
    specify { expect(typecast('blablabla')).to be_nil }
    specify { expect(typecast(DateTime.new(2013, 6, 13, 23, 13))).to eq(date) }
    specify { expect(typecast(Time.new(2013, 6, 13, 23, 13))).to eq(date) }
    specify { expect(typecast(Date.new(2013, 6, 13))).to eq(date) }
  end
end
