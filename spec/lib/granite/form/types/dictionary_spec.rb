# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Dictionary do
  subject(:type) { described_class.new(subtype_definition) }

  let(:element_type) { Dummy }
  let(:subtype_definition) { Granite::Form::Types::Object.new(element_type, reflection, nil) }
  let(:reflection) { build_reflection }
  let(:dummy) { Dummy.new }
  let(:dummy2) { Dummy.new }

  def build_reflection(**options)
    Granite::Form::Model::Attributes::Reflections::Dictionary.new(:field, options)
  end

  before { stub_class :dummy }

  describe '#prepare' do
    specify { expect(subject.prepare(one: dummy, two: Object.new)).to eq('one' => dummy, 'two' => nil) }
    specify { expect(subject.prepare(three: dummy)).to eq('three' => dummy) }
    specify { expect(subject.prepare([['one', dummy]])).to eq('one' => dummy) }
    specify { expect(subject.prepare(nil)).to eq({}) }

    context 'when keys are set' do
      let(:reflection) { build_reflection keys: %w[one two] }

      specify { expect(subject.prepare(three: dummy)).to eq({}) }
      specify { expect(subject.prepare(nil)).to eq({}) }
    end
  end
end
