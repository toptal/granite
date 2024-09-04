# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::ActiveSupport::TimeZone do
  describe 'typecasting' do
    include_context 'type setup', 'ActiveSupport::TimeZone'

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast(Object.new)).to be_nil }
    specify { expect(typecast(Time.now)).to be_nil }
    specify { expect(typecast('blablabla')).to be_nil }
    specify { expect(typecast(TZInfo::Timezone.all.first)).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast('Moscow')).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast('+4')).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast('-3')).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast('3600')).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast('-7200')).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast(4)).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast(-3)).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast(3600)).to be_a ActiveSupport::TimeZone }
    specify { expect(typecast(-7200)).to be_a ActiveSupport::TimeZone }
  end
end
