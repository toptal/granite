# spec: unit

require 'granite/action'
require 'granite/represents/reflection'

RSpec.describe Granite::Represents::Reflection do
  describe '.attribute_class' do
    subject { described_class }

    its(:attribute_class) { is_expected.to eq Granite::Represents::Attribute }
  end

  describe '.build' do
    before do
      stub_model_class 'DummyUser' do
        self.table_name = 'users'
      end
    end

    context 'when attribute represents nil' do
      let(:instance) { Target.new }

      before do
        stub_class(:target, Object) do
          include Granite::Base

          references_one :author, class_name: 'DummyUser'
          attribute :field, Object
          represents :field, of: :author
        end
      end

      specify do
        expect(Target).to be_method_defined(:field)
        expect(Target).to be_method_defined(:field=)
        expect(Target).to be_method_defined(:field?)
        expect(Target).to be_method_defined(:field_before_type_cast)
        expect(Target).to be_method_defined(:field_default)
        expect(Target).to be_method_defined(:field_values)
        expect { instance.validate }.to change { instance.errors.messages }.to(author: ["can't be blank"])
      end
    end

    context 'when attribute represents not nil value' do
      let(:instance) { Target.new }

      before do
        stub_class(:target, Object) do
          include Granite::Base

          references_one :author, default: {}, class_name: 'DummyUser'
          attribute :field, Object
          represents :field, of: :author
        end
      end

      specify do
        described_class.build(Target, Target, :field, of: :author)

        expect(Target).to be_method_defined(:field)
        expect(Target).to be_method_defined(:field=)
        expect(Target).to be_method_defined(:field?)
        expect(Target).to be_method_defined(:field_before_type_cast)
        expect(Target).to be_method_defined(:field_default)
        expect(Target).to be_method_defined(:field_values)
        expect(instance).to be_valid
      end
    end
  end
end
