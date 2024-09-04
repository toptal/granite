# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::HashWithActionControllerParameters do
  describe 'typecasting' do
    include_context 'type setup', 'Hash'

    before(:all) do
      require 'action_controller'
      Class.new(ActionController::Base)
    end

    let(:to_h) { { 'x' => { 'foo' => 'bar' }, 'y' => 2 } }
    let(:parameters) { ActionController::Parameters.new(to_h) }

    specify { expect(typecast(nil)).to be_nil }
    specify { expect(typecast(to_h)).to eq(to_h) }
    specify { expect(typecast(parameters)).to be_nil }
    specify { expect(typecast(parameters.permit(:y, x: [:foo]))).to eq(to_h) }
  end
end
