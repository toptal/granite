# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Time do
  describe 'typecasting' do
    include_context 'type setup', 'Time'

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast('2013-06-13 23:13')).to eq('2013-06-13 23:13'.to_time) }
    specify { expect(typecast('2013-55-55 55:55')).to be_nil }
    specify { expect(typecast('blablabla')).to be_nil }
    specify { expect(typecast(Date.new(2013, 6, 13))).to eq(Time.new(2013, 6, 13, 0, 0)) }
    specify { expect(typecast(DateTime.new(2013, 6, 13, 19, 13))).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
    specify { expect(typecast(Time.new(2013, 6, 13, 23, 13))).to eq(Time.new(2013, 6, 13, 23, 13)) }

    context 'Time.zone set' do
      around { |example| Time.use_zone('Bangkok', &example) }

      specify { expect(typecast(nil)).to be_nil }
      specify { expect(typecast('2013-06-13 23:13')).to eq(Time.zone.parse('2013-06-13 23:13')) }
      specify { expect(typecast('2013-55-55 55:55')).to be_nil }
      specify { expect(typecast('blablabla')).to be_nil }
      specify { expect(typecast(Date.new(2013, 6, 13))).to eq(Time.new(2013, 6, 13, 0, 0)) }
      specify { expect(typecast(DateTime.new(2013, 6, 13, 19, 13))).to eq(DateTime.new(2013, 6, 13, 19, 13).to_time) }
      specify { expect(typecast(Time.new(2013, 6, 13, 23, 13))).to eq(Time.new(2013, 6, 13, 23, 13)) }
    end
  end
end
