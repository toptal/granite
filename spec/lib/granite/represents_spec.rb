# spec: unit

require 'active_support/concern'
require 'granite/represents'
require 'granite/action'

RSpec.describe Granite::Represents do
  subject(:action) { Action.new(attributes) }
  let(:attributes) { {} }

  before do
    stub_class(:model) do
      include ActiveModel::Validations

      attr_accessor :field

      def initialize
        @field = 1
      end
    end

    stub_class(:action, Granite::Action) do
      allow_if { true }

      represents :field, of: :model

      def model
        @model ||= Model.new
      end
    end
  end

  shared_examples 'sync attribute value' do
    it 'syncs before validation if value was changed' do
      subject
      expect_any_instance_of(Granite::Represents::Attribute).to receive(:sync)
      subject.field = new_value
      subject.valid?
    end
  end

  it 'contains custom represented attribute' do
    expect(Action.reflect_on_attribute(:field)).to be_a(Granite::Represents::Reflection)
  end

  it 'fetches value from represented model' do
    expect(subject.field).to eq(subject.model.field)
  end

  it 'does not sync value before validation if value was not changed' do
    subject
    expect_any_instance_of(Granite::Represents::Attribute).not_to receive(:sync)
    subject.valid?
  end

  context 'when value was changed' do
    let(:attributes) { {field: 2} }
    let(:new_value) { 3 }

    include_examples 'sync attribute value'
  end

  context 'when attrbute has default value' do
    before do
      stub_class(:model) do
        include ActiveModel::Validations

        attr_accessor :field
      end

      stub_class(:action, Granite::Action) do
        allow_if { true }

        represents :field, of: :model, default: 10

        def model
          @model ||= Model.new
        end
      end
    end

    context 'when new value equal default value' do
      let(:new_value) { 10 }

      include_examples 'sync attribute value'
    end

    context 'when new value not equal default value' do
      let(:new_value) { 5 }

      include_examples 'sync attribute value'
    end
  end
end
