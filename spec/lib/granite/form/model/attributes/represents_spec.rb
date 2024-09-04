require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Represents do
  before do
    stub_model_granite_form :author
    stub_model_granite_form(:model) do
      def author
        @author ||= Author.new
      end
    end
  end

  let(:model) { Model.new }
  let(:attribute) { add_attribute }

  def add_attribute(*args)
    options = args.extract_options!.reverse_merge(of: :author)
    name = args.first || :name
    reflection = Model.add_attribute(Granite::Form::Model::Attributes::Reflections::Represents, name, options)
    model.attribute(reflection.name)
  end

  describe '#initialize' do
    before { Author.attribute :name, String, default: 'Default Name' }

    let(:attributes) { { foo: 'bar' } }

    it { expect { Model.new(attributes) }.not_to(change { attributes }) }

    it { expect(attribute.read).to eq('Default Name') }
    it { expect(attribute.read_before_type_cast).to eq('Default Name') }

    it { expect(add_attribute(default: -> { 'Field Default' }).read).to eq('Default Name') }

    context 'when owner changes value after initialize' do
      before do
        attribute
        model.author.name = 'Changed Name'
      end

      it { expect(attribute.read).to eq('Default Name') }
      it { expect(attribute.read_before_type_cast).to eq('Default Name') }
    end
  end

  describe '#sync' do
    before do
      Author.attribute :name, String
      attribute.write('New name')
    end

    it { expect { attribute.sync }.to change { model.author.name }.from(nil).to('New name') }

    context 'when represented object does not respond to attribute name' do
      let(:attribute) { add_attribute(:unknown_attribute) }

      it { expect { attribute.sync }.not_to raise_error }
    end
  end

  describe '#changed?' do
    before { Author.attribute :name, Boolean }

    specify do
      expect(model).to receive(:name_changed?)
      expect(attribute).not_to be_changed
    end

    context 'when attribute has default value' do
      let(:attribute) { add_attribute default: -> { true } }

      specify do
        expect(model).not_to receive(:name_changed?)
        expect(attribute).to be_changed
      end
    end

    context 'when attribute has false as default value' do
      let(:attribute) { add_attribute default: false }

      specify do
        expect(model).not_to receive(:name_changed?)
        expect(attribute).to be_changed
      end
    end
  end

  describe 'typecasting' do
    before { Author.attribute :name, String }

    def typecast(value)
      attribute.write(value)
      attribute.read
    end

    it 'returns original value when it has right class' do
      expect(typecast('1')).to eq '1'
    end

    it 'returns converted value to a proper type' do
      expect(typecast(1)).to eq '1'
    end

    it 'ignores nil' do
      expect(typecast(nil)).to be_nil
    end
  end
end
