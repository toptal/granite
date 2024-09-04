require 'spec_helper'
require 'granite/form/base'

RSpec.describe Granite::Form::Model::Associations::Reflections::EmbedsAny do
  describe '#build' do
    subject { described_class.build(User, User, :projects) {}.klass.new }

    before do
      stub_model_granite_form(:project) do
        attribute :title, String
      end
      stub_model_granite_form(:user) do
        include Granite::Form::Model::Associations

        attribute :name, String
        embeds_many :projects
      end
    end

    it { is_expected.to be_a(Granite::Form::Model) }
    it { is_expected.to be_a(Granite::Form::Model::Primary) }
    it { is_expected.to be_a(Granite::Form::Model::Persistence) }
    it { is_expected.to be_a(Granite::Form::Model::Associations) }

    context 'when Granite::Form.base_concern is defined' do
      before do
        stub_const('MyModule', Module.new)

        allow(Granite::Form).to receive(:base_concern).and_return(MyModule)

        stub_model_granite_form(:user) do
          include Granite::Form::Model::Associations

          embeds_many :projects
        end
      end

      it { is_expected.to be_a(MyModule) }
    end
  end
end
