require 'spec_helper'

RSpec.describe Granite::Form::Model::Persistence do
  let(:model) do
    stub_model do
      include Granite::Form::Model::Persistence

      attribute :name
      attribute :count, default: 0
    end
  end

  specify { expect(model.new).not_to be_persisted }

  describe '#instantiate' do
    specify { expect(model.instantiate({})).to be_an_instance_of model }
    specify { expect(model.instantiate({})).to be_persisted }

    context do
      subject(:instance) { model.instantiate(name: 'Hello', foo: 'Bar') }

      specify { expect(subject.instance_variable_get(:@initial_attributes)).to eq({ name: 'Hello' }.stringify_keys) }
    end
  end

  describe '#instantiate_collection' do
    context do
      subject(:instances) { model.instantiate_collection(name: 'Hello', foo: 'Bar') }

      specify { expect(subject).to be_a Array }

      specify do
        expect(subject.first.instance_variable_get(:@initial_attributes)).to eq({ name: 'Hello' }.stringify_keys)
      end
    end

    context do
      subject(:instances) { model.instantiate_collection([{ name: 'Hello', foo: 'Bar' }, { name: 'World' }]) }

      before { model.send(:include, Granite::Form::Model::Scopes) }

      specify { expect(subject).to be_a Granite::Form::Model::Scopes::ScopeProxy }
      specify { expect(subject.count).to eq(2) }

      specify do
        expect(subject.first.instance_variable_get(:@initial_attributes)).to eq({ name: 'Hello' }.stringify_keys)
      end

      specify do
        expect(subject.second.instance_variable_get(:@initial_attributes)).to eq({ name: 'World' }.stringify_keys)
      end
    end
  end
end
