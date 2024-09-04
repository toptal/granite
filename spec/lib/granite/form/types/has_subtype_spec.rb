# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::HasSubtype do
  subject(:type) { described_class.new(subtype_definition) }

  let(:subtype_definition) { Granite::Form::Types::Object.new(Dummy, reflection, nil) }
  let(:reflection) { Granite::Form::Model::Attributes::Reflections::Base.new(:field) }
  let(:dummy_object) { Dummy.new }

  before { stub_class :dummy }

  describe '#build_duplicate' do
    subject { type.build_duplicate(new_reflection, new_model) }

    let(:new_model) { double('new_model') }
    let(:new_reflection) { double('new_reflection') }

    it {
      expect(subject).to have_attributes(subtype_definition: have_attributes(type: Dummy, reflection: new_reflection,
                                                                             owner: new_model))
    }
  end
end
