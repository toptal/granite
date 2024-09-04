require 'spec_helper'

RSpec.describe Granite::Form::Model::Scopes do
  let(:model) do
    stub_model_granite_form do
      include Granite::Form::Model::Scopes

      attribute :name, String

      class << self
        def except_first
          scope[1..]
        end

        def no_mars
          scope.delete_if { |i| i.name == 'Mars' }
        end

        private

        def hidden_method() end
      end
    end
  end

  let(:hash_scoped_model) do
    stub_model_granite_form do
      include Granite::Form::Model::Scopes
      scopify Hash
    end
  end

  describe '.scope_class' do
    specify { expect(model.scope_class).to be < Array }
    specify { expect(model.scope_class).to eq(model::ScopeProxy) }
    specify { expect(model.scope_class._scope_model).to eq(model) }
    specify { expect(model.scope_class.new).to be_empty }

    specify { expect(hash_scoped_model.scope_class).to be < Hash }
    specify { expect(hash_scoped_model.scope_class).to eq(hash_scoped_model::ScopeProxy) }
    specify { expect(hash_scoped_model.scope_class._scope_model).to eq(hash_scoped_model) }
    specify { expect(hash_scoped_model.scope_class.new).to be_empty }

    context do
      let(:scope) { model.scope([model.new(name: 'Hello'), model.new(name: 'World'), model.new(name: 'Mars')]) }

      specify { expect(scope).to be_instance_of model.scope_class }

      specify do
        expect do
          model.scope([model.new(name: 'Hello'), {}])
        end.to raise_error Granite::Form::AssociationTypeMismatch
      end

      context 'scopes' do
        specify { expect(scope.except_first).to be_instance_of model.scope_class }
        specify { expect(scope.no_mars).to be_instance_of model.scope_class }
        specify { expect(scope.except_first).to eq(model.scope([model.new(name: 'World'), model.new(name: 'Mars')])) }
        specify { expect(scope.no_mars).to eq(model.scope([model.new(name: 'Hello'), model.new(name: 'World')])) }
        specify { expect(scope.except_first.no_mars).to eq(model.scope([model.new(name: 'World')])) }
        specify { expect(scope.no_mars.except_first).to eq(model.scope([model.new(name: 'World')])) }
        specify { expect { scope.hidden_method }.to raise_error NoMethodError }

        specify { expect(scope).to respond_to(:no_mars) }
        specify { expect(scope).to respond_to(:except_first) }
        specify { expect(scope).not_to respond_to(:hidden_method) }
      end
    end
  end

  context do
    let!(:ancestor) do
      stub_model_granite_form do
        include Granite::Form::Model::Scopes
      end
    end

    let!(:descendant1) do
      Class.new ancestor
    end

    let!(:descendant2) do
      Class.new ancestor
    end

    specify { expect(descendant1.scope_class).to be < Array }
    specify { expect(descendant2.scope_class).to be < Array }
    specify { expect(ancestor.scope_class).not_to eq(descendant1.scope_class) }
    specify { expect(descendant1.scope_class).not_to eq(descendant2.scope_class) }
  end
end
