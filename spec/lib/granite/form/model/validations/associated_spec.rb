require 'spec_helper'

RSpec.describe Granite::Form::Model::Validations::AssociatedValidator do
  before do
    stub_model_granite_form(:validated_assoc) do
      include Granite::Form::Model::Persistence

      attribute :name, String

      validates_presence_of :name
    end

    stub_model_granite_form(:unvalidated_assoc) do
      include Granite::Form::Model::Persistence

      attribute :name, String
    end

    stub_model_granite_form(:main) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :name, String

      validates_presence_of :name
      validates_associated :validated_one, :unvalidated_one, :validated_many, :unvalidated_many

      embeds_one :validated_one, validate: false, class_name: 'ValidatedAssoc'
      embeds_one :unvalidated_one, class_name: 'UnvalidatedAssoc'
      embeds_many :validated_many, class_name: 'ValidatedAssoc'
      embeds_many :unvalidated_many, class_name: 'UnvalidatedAssoc'
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_one: { name: 'name' } }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_one: {} }

    it { is_expected.not_to be_valid }

    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to(validated_one: ['is invalid'])
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_one: { name: 'name' } }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_one: {} }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{ name: 'name' }] }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{}] }

    it { is_expected.not_to be_valid }

    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_many.0.name': ["can't be blank"], validated_many: ['is invalid'])
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_many: [{ name: 'name' }] }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', unvalidated_many: [{}] }

    it { is_expected.to be_valid }
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{ name: 'name' }], validated_one: {} }

    it { is_expected.not_to be_valid }

    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to(validated_one: ['is invalid'])
    end
  end

  context do
    subject(:instance) { Main.instantiate name: 'hello', validated_many: [{}], validated_one: { name: 'name' } }

    it { is_expected.not_to be_valid }

    specify do
      expect { instance.validate }.to change { instance.errors.messages }
        .to('validated_many.0.name': ["can't be blank"], validated_many: ['is invalid'])
    end
  end
end
