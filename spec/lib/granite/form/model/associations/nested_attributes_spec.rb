require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::NestedAttributes do
  context '' do
    before do
      stub_model :user do
        include Granite::Form::Model::Associations

        attribute :email, String
        embeds_one :profile
        embeds_many :projects

        accepts_nested_attributes_for :profile, :projects
      end
    end

    include_examples 'nested attributes'
  end

  describe '#assign_attributes' do
    specify 'invent a good example'
  end
end
