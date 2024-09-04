require 'spec_helper'

RSpec.describe Granite::Form::Types::Collection do
  subject(:type) { described_class.new(subtype_definition) }

  let(:element_type) { Dummy }
  let(:subtype_definition) { Granite::Form::Types::Object.new(element_type, reflection, nil) }
  let(:reflection) { Granite::Form::Model::Attributes::Reflections::Base.new(:field) }
  let(:dummy_object) { Dummy.new }

  before { stub_class :dummy }

  describe '#prepare' do
    specify { expect(subject.prepare([dummy_object, Object.new])).to eq([dummy_object, nil]) }
    specify { expect(subject.prepare(dummy_object)).to eq([dummy_object]) }

    context 'with Hash collection' do
      let(:element_type) { Hash }

      specify { expect(subject.prepare([{ key: 'value' }])).to eq([{ key: 'value' }]) }
    end
  end
end
