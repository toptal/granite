require 'spec_helper'

RSpec.describe Granite::Form::Config do
  subject { Granite::Form::Config.send :new }

  describe '#include_root_in_json' do
    its(:include_root_in_json) { is_expected.to eq false }

    specify do
      expect { subject.include_root_in_json = true }
        .to change { subject.include_root_in_json }.from(false).to(true)
    end
  end

  describe '#i18n_scope' do
    its(:i18n_scope) { is_expected.to eq :granite }

    specify do
      expect { subject.i18n_scope = :data_model }
        .to change { subject.i18n_scope }.from(:granite).to(:data_model)
    end
  end

  describe '#logger' do
    its(:logger) { is_expected.to be_a Logger }
  end

  describe '#primary_attribute' do
    its(:primary_attribute) { is_expected.to eq :id }

    specify do
      expect { subject.primary_attribute = :identified }
        .to change { subject.primary_attribute }.from(:id).to(:identified)
    end
  end

  describe '#normalizer' do
    specify do
      expect { subject.normalizer(:name) {} }
        .to change {
          begin
            subject.normalizer(:name)
          rescue Granite::Form::NormalizerMissing
            nil
          end
        }.from(nil).to(an_instance_of(Proc))
    end

    specify { expect { subject.normalizer(:wrong) }.to raise_error Granite::Form::NormalizerMissing }
  end

  describe '#typecaster' do
    specify do
      expect { subject.typecaster('Object', &:to_s) }
        .to change { subject.types['Object'] }.from(nil).to(an_instance_of(Class))

      expect(subject.types['Object'].new(Object, nil, stub_model.new).typecast(1)).to eq('1')
    end

    specify do
      expect { subject.typecaster(Object) {} }
        .to change { subject.types['Object'] }.from(nil).to(an_instance_of(Class))
    end

    specify do
      expect { subject.typecaster('object') {} }
        .to change { subject.types['Object'] }.from(nil).to(an_instance_of(Class))
    end
  end

  describe '#type_for' do
    let(:definition) { subject.types['Numeric'] }

    before { subject.typecaster('Numeric') {} }

    specify do
      expect(subject.type_for(Numeric)).to eq(definition)
      expect(subject.type_for(Integer)).to eq(definition)
      expect { subject.type_for(String) }.to raise_error(Granite::Form::TypecasterMissing)
    end
  end
end
