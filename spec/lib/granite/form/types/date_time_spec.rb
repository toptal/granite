# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::DateTime do
  describe 'typecasting' do
    include_context 'type setup', 'DateTime'
    let(:datetime) { DateTime.new(2013, 6, 13, 23, 13) }

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast('2013-06-13 23:13')).to eq(datetime) }
    specify { expect(typecast('2013-55-55 55:55')).to be_nil }
    specify { expect(typecast('blablabla')).to be_nil }
    specify { expect(typecast(Date.new(2013, 6, 13))).to eq(DateTime.new(2013, 6, 13, 0, 0)) }
    specify { expect(typecast(Time.utc(2013, 6, 13, 23, 13).utc)).to eq(datetime) }
    specify { expect(typecast(DateTime.new(2013, 6, 13, 23, 13))).to eq(datetime) }
  end
end
