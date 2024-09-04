# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Reflections::Base::BuildTypeDefinition do
  def build_type_definition(**options)
    @reflection = Granite::Form::Model::Attributes::Reflections::Base.new(:field, options)
    described_class.new(owner, @reflection).call
  end

  def have_type(type)
    have_attributes(type: type, reflection: @reflection, owner: owner)
  end

  before do
    stub_class_granite_form :owner
    stub_class_granite_form(:dummy, String)
  end

  let(:owner) { Owner.new }

  specify { expect { build_type_definition }.to raise_error('Type is not specified for `field`') }
  specify { expect(build_type_definition(type: String)).to have_type(String) }
  specify { expect(build_type_definition(type: :string)).to have_type(String) }
  specify { expect(build_type_definition(type: Dummy)).to have_type(Dummy) }
  specify { expect { build_type_definition(type: :blabla) }.to raise_error NameError }
end
