# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Types::Object do
  subject(:type) { build_type(reflection: reflection) }

  let(:model) { Model.new }
  let(:reflection) { build_reflection }

  before do
    stub_model :model
  end

  def build_reflection(name: :field, **options)
    Granite::Form::Model::Attributes::Reflections::Base.new(name, options)
  end

  def build_type(type: String, reflection: nil, **options)
    described_class.new(type, reflection || build_reflection(**options), model)
  end

  describe '#initialize' do
    it { is_expected.to have_attributes(type: String, reflection: reflection, owner: model) }
  end

  describe '#build_duplicate' do
    subject { type.build_duplicate(new_reflection, new_model) }

    let(:new_model) { double('new_model') }
    let(:new_reflection) { Granite::Form::Model::Attributes::Reflections::Base.new(:new_field) }

    it { is_expected.to have_attributes(type: String, reflection: new_reflection, owner: new_model) }
  end

  describe 'typecasting' do
    before { stub_class(:descendant) }

    context 'with Object type' do
      include_context 'type setup', 'Object'

      specify { expect(typecast('hello')).to eq('hello') }
      specify { expect(typecast([])).to eq([]) }
      specify { expect(typecast(Descendant.new)).to be_a(Descendant) }
      specify { expect(typecast(Object.new)).to be_a(Object) }
      specify { expect(typecast(nil)).to be_nil }
    end

    context 'with Descendant type' do
      include_context 'type setup', 'Descendant'

      before { stub_class(:descendant2, Descendant) }

      specify { expect(typecast('hello')).to be_nil }
      specify { expect(typecast([])).to be_nil }
      specify { expect(typecast(Descendant.new)).to be_a(Descendant) }
      specify { expect(typecast(Descendant2.new)).to be_a(Descendant2) }
      specify { expect(typecast(Object.new)).to be_nil }
      specify { expect(typecast(nil)).to be_nil }
    end
  end

  describe '#enum' do
    before { allow(model).to receive_messages(value: 1..5) }

    specify { expect(build_type.enum).to eq([].to_set) }
    specify { expect(build_type(enum: []).enum).to eq([].to_set) }
    specify { expect(build_type(enum: 'hello').enum).to eq(['hello'].to_set) }
    specify { expect(build_type(enum: %w[hello world]).enum).to eq(%w[hello world].to_set) }
    specify { expect(build_type(enum: [1..5]).enum).to eq([1..5].to_set) }
    specify { expect(build_type(enum: 1..5).enum).to eq((1..5).to_a.to_set) }
    specify { expect(build_type(enum: -> { 1..5 }).enum).to eq((1..5).to_a.to_set) }
    specify { expect(build_type(enum: -> { 'hello' }).enum).to eq(['hello'].to_set) }
    specify { expect(build_type(enum: -> { ['hello', 42] }).enum).to eq(['hello', 42].to_set) }
    specify { expect(build_type(enum: -> { value }).enum).to eq((1..5).to_a.to_set) }
  end

  describe '#prepare' do
    specify { expect(build_type.prepare('anything')).to eq('anything') }
    specify { expect(build_type(enum: %w[hello 42]).prepare('hello')).to eq('hello') }
    specify { expect(build_type(enum: %w[hello 42]).prepare('world')).to eq(nil) }
    specify { expect(build_type(enum: %w[hello 42]).prepare('42')).to eq('42') }
    specify { expect(build_type(enum: %w[hello 42]).prepare(42)).to eq(nil) }
    specify { expect(build_type(enum: -> { 'hello' }).prepare('hello')).to eq('hello') }
    specify { expect(build_type(type: Integer, enum: -> { 1..5 }).prepare(2)).to eq(2) }
    specify { expect(build_type(type: Integer, enum: -> { 1..5 }).prepare(42)).to eq(nil) }
  end
end
