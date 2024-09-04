require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Reflections::Represents do
  def reflection(options = {})
    described_class.new(:field, options.reverse_merge(of: :subject))
  end

  describe '.build' do
    def build_reflection(column = :name, **options)
      described_class.build(Target, Target, column, of: :subject, **options)
    end

    before do
      stub_model_granite_form(:author) do
        attribute :name, String
        attribute :age, Integer
      end

      stub_model_granite_form(:target) do
        attribute :author, Author
        alias_attribute :subject, :author
      end
    end

    let(:instance) { Target.new attributes }
    let(:attributes) { { subject: Author.new } }
    let!(:reflection) { build_reflection }

    it { expect(reflection.reference).to eq('author') }

    it do
      expect(Target).to be_method_defined(:name)
      expect(Target).to be_method_defined(:name=)
      expect(Target).to be_method_defined(:name?)
      expect(Target).to be_method_defined(:name_before_type_cast)
      expect(Target).to be_method_defined(:name_default)
      expect(Target).to be_method_defined(:name_values)
    end

    it { expect(instance).to be_valid }

    context 'with missing `of` attribute value' do
      let(:attributes) { super().except(:subject) }

      it { expect { instance.validate }.to change { instance.errors.messages }.to(author: ["can't be blank"]) }

      context 'with multiple reflections' do
        before { build_reflection(:age) }

        it { expect { instance.validate }.to change { instance.errors.messages }.to(author: ["can't be blank"]) }
      end

      context 'when validate_reference is false' do
        let(:reflection) { build_reflection(validate_reference: false) }

        it { expect { instance.validate }.not_to(change { instance.errors.messages }) }
      end
    end
  end

  describe '#type' do
    specify { expect(reflection.type).to eq(Object) }
    specify { expect(reflection(type: :whatever).type).to eq(Object) }
  end

  describe '#reference' do
    specify { expect { reflection(of: nil) }.to raise_error ArgumentError }
    specify { expect(reflection(of: :subject).reference).to eq('subject') }
  end

  describe '#column' do
    specify { expect(reflection.column).to eq('field') }
    specify { expect(reflection(column: 'hello').column).to eq('hello') }
  end

  describe '#reader' do
    specify { expect(reflection.reader).to eq('field') }
    specify { expect(reflection(column: 'hello').reader).to eq('hello') }
    specify { expect(reflection(reader: 'world').reader).to eq('world') }
  end

  describe '#reader_before_type_cast' do
    specify { expect(reflection.reader_before_type_cast).to eq('field_before_type_cast') }
    specify { expect(reflection(column: 'hello').reader_before_type_cast).to eq('hello_before_type_cast') }
    specify { expect(reflection(reader: 'world').reader_before_type_cast).to eq('world_before_type_cast') }
  end

  describe '#writer' do
    specify { expect(reflection.writer).to eq('field=') }
    specify { expect(reflection(column: 'hello').writer).to eq('hello=') }
    specify { expect(reflection(writer: 'world').writer).to eq('world=') }
  end
end
