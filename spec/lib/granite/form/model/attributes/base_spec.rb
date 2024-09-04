require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Base do
  let(:model) { Dummy.new }

  before { stub_model(:dummy) }

  def attribute(*args)
    options = args.extract_options!
    Dummy.add_attribute(Granite::Form::Model::Attributes::Reflections::Base, :field,
                        options.reverse_merge(type: Object))
    model.attribute(:field)
  end

  describe '#read' do
    let(:field) do
      normalizer = ->(v) { v ? v.strip : v }
      attribute(type: String, normalizer: normalizer, default: :world, enum: %w[hello 42 world])
    end
    let(:object) { Object.new }

    specify { expect(field.tap { |r| r.write(nil) }.read).to be_nil }
    specify { expect(field.tap { |r| r.write('') }.read).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read).to eq(object) }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read).to be_nil }
    end
  end

  describe '#read_before_type_cast' do
    let(:field) { attribute(type: String, normalizer: ->(v) { v.strip }, default: :world, enum: %w[hello 42 world]) }
    let(:object) { Object.new }

    specify { expect(field.tap { |r| r.write(nil) }.read_before_type_cast).to be_nil }
    specify { expect(field.tap { |r| r.write('') }.read_before_type_cast).to eq('') }
    specify { expect(field.tap { |r| r.write(:world) }.read_before_type_cast).to eq(:world) }
    specify { expect(field.tap { |r| r.write(object) }.read_before_type_cast).to eq(object) }

    context ':readonly' do
      specify { expect(attribute(readonly: true).tap { |r| r.write('string') }.read_before_type_cast).to be_nil }
    end
  end

  describe '#came_from_user?' do
    let(:field) { attribute(type: String, default: 'world') }
    let(:object) { Object.new }

    specify { expect(field.came_from_user?).to eq(false) }
    specify { expect(field.tap { |r| r.write('value') }.came_from_user?).to eq(true) }
  end

  describe '#came_from_default?' do
    let(:field) { attribute(type: String, default: 'world') }
    let(:object) { Object.new }

    specify { expect(field.came_from_default?).to eq(true) }
    specify { expect(field.tap { |r| r.write('value') }.came_from_default?).to eq(false) }
  end

  describe '#value_present?' do
    let(:field) { attribute }

    specify { expect(field.tap { |r| r.write(0) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(42) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(true) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(false) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(nil) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write('') }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write(:world) }).to be_value_present }
    specify { expect(field.tap { |r| r.write(Object.new) }).to be_value_present }
    specify { expect(field.tap { |r| r.write([]) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write([42]) }).to be_value_present }
    specify { expect(field.tap { |r| r.write({}) }).not_to be_value_present }
    specify { expect(field.tap { |r| r.write(hello: 42) }).to be_value_present }
  end

  describe '#query' do
    let(:field) { attribute }

    specify { expect(field.tap { |r| r.write(0) }.query).to be(false) }
    specify { expect(field.tap { |r| r.write(42) }.query).to be(true) }
    specify { expect(field.tap { |r| r.write(true) }.query).to be(true) }
    specify { expect(field.tap { |r| r.write(false) }.query).to be(false) }
    specify { expect(field.tap { |r| r.write(nil) }.query).to be(false) }
    specify { expect(field.tap { |r| r.write('') }.query).to be(false) }
    specify { expect(field.tap { |r| r.write(:world) }.query).to be(true) }
    specify { expect(field.tap { |r| r.write(Object.new) }.query).to be(true) }
    specify { expect(field.tap { |r| r.write([]) }.query).to be(false) }
    specify { expect(field.tap { |r| r.write([42]) }.query).to be(true) }
    specify { expect(field.tap { |r| r.write({}) }.query).to be(false) }
    specify { expect(field.tap { |r| r.write(hello: 42) }.query).to be(true) }
  end

  describe '#readonly?' do
    specify { expect(attribute).not_to be_readonly }
    specify { expect(attribute(readonly: false)).not_to be_readonly }
    specify { expect(attribute(readonly: true)).to be_readonly }
    specify { expect(attribute(readonly: -> { false })).not_to be_readonly }
    specify { expect(attribute(readonly: -> { true })).to be_readonly }
  end

  describe '#type_definition' do
    subject { attr.type_definition }

    let(:attr) { attribute(type: String) }

    it { is_expected.to have_attributes(type: String, reflection: subject.reflection, owner: model) }
  end

  describe '#inspect_attribute' do
    let(:field) { attribute(type: type) }
    let(:object) { Object.new }

    {
      'hello' => 'field: "hello"',
      123 => 'field: 123',
      Date.new(2023, 6, 20) => 'field: "2023-06-20"',
      DateTime.new(2023, 6, 20, 12, 30) => 'field: "2023-06-20 12:30:00"',
      Time.new(2023, 6, 20, 12, 30) => 'field: "2023-06-20 12:30:00"'
    }.each do |input, expected_output|
      context "attribute type is #{input.class}" do
        let(:type) { input.class }

        specify { expect(field.tap { |r| r.write(input) }.inspect_attribute).to eq(expected_output) }
      end
    end
  end
end
