# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Reflections::Collection::BuildTypeDefinition do
  def build_type_definition(name = :name, **options)
    @reflection = Granite::Form::Model::Attributes::Reflections::Collection.new(name, options)
    described_class.new(owner, @reflection).call
  end

  def have_collection_type(type)
    subtype_definition = have_attributes(type: type, reflection: @reflection, owner: owner)
    have_attributes(subtype_definition: subtype_definition)
  end

  before do
    stub_class :owner
    stub_class(:dummy, String)
  end

  let(:owner) { Owner.new }

  it { expect(build_type_definition(type: String)).to have_collection_type(String) }
end
