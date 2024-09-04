require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes do
  let(:model) do
    stub_model do
      include Granite::Form::Model::Associations

      attribute :id, Integer
      attribute :full_name, String
      alias_attribute :name, :full_name

      embeds_one(:author) {}
      embeds_many(:projects) {}
    end
  end

  describe '.reflect_on_attribute' do
    specify { expect(model.reflect_on_attribute(:full_name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute('full_name').name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:name).name).to eq('full_name') }
    specify { expect(model.reflect_on_attribute(:foobar)).to be_nil }
  end

  describe '.has_attribute?' do
    specify { expect(model.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.has_attribute?(:name)).to eq(true) }
    specify { expect(model.has_attribute?(:foobar)).to eq(false) }
  end

  describe '.attribute_names' do
    specify { expect(stub_model.attribute_names).to eq([]) }
    specify { expect(model.attribute_names).to eq(%w[id full_name author projects]) }
    specify { expect(model.attribute_names(false)).to eq(%w[id full_name]) }
  end

  describe '.inspect' do
    specify { expect(stub_model.inspect).to match(/#<Class:0x\w+>\(no attributes\)/) }
    specify { expect(stub_model(:user).inspect).to eq('User(no attributes)') }

    specify do
      expect(stub_model do
               include Granite::Form::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.inspect).to match(/#<Class:0x\w+>\(\*count: Integer, object: Object\)/)
    end

    specify do
      expect(stub_model(:user) do
               include Granite::Form::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.inspect).to match('User(*count: Integer, object: Object)')
    end
  end

  describe '#==' do
    subject { model.new name: 'hello', count: 42 }

    let(:model) do
      stub_model do
        attribute :name, String
        attribute :count, Float, default: 0
      end
    end

    it { is_expected.not_to eq(nil) }
    it { is_expected.not_to eq('hello') }
    it { is_expected.not_to eq(Object.new) }
    it { is_expected.not_to eq(model.new) }
    it { is_expected.not_to eq(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eq(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eq(model.new(name: 'hello', count: 42)) }

    it { is_expected.not_to eql(nil) }
    it { is_expected.not_to eql('hello') }
    it { is_expected.not_to eql(Object.new) }
    it { is_expected.not_to eql(model.new) }
    it { is_expected.not_to eql(model.new(name: 'hello1', count: 42)) }
    it { is_expected.not_to eql(model.new(name: 'hello', count: 42.1)) }
    it { is_expected.to eql(model.new(name: 'hello', count: 42)) }
  end

  describe '#attribute' do
    let(:instance) { model.new }

    specify { expect(instance.attribute(:full_name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute('full_name').reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:name).reflection.name).to eq('full_name') }
    specify { expect(instance.attribute(:foobar)).to be_nil }

    specify { expect(instance.attribute('full_name')).to equal(instance.attribute(:name)) }
  end

  describe '#has_attribute?' do
    specify { expect(model.new.has_attribute?(:full_name)).to eq(true) }
    specify { expect(model.new.has_attribute?('full_name')).to eq(true) }
    specify { expect(model.new.has_attribute?(:name)).to eq(true) }
    specify { expect(model.new.has_attribute?(:foobar)).to eq(false) }
  end

  describe '#attribute_names' do
    specify { expect(stub_model.new.attribute_names).to eq([]) }
    specify { expect(model.new.attribute_names).to eq(%w[id full_name author projects]) }
    specify { expect(model.new.attribute_names(false)).to eq(%w[id full_name]) }
  end

  describe '#attribute_present?' do
    specify { expect(model.new.attribute_present?(:name)).to be(false) }
    specify { expect(model.new(name: '').attribute_present?(:name)).to be(false) }
    specify { expect(model.new(name: 'Name').attribute_present?(:name)).to be(true) }
  end

  describe '#attributes' do
    specify { expect(stub_model.new.attributes).to eq({}) }

    specify do
      expect(model.new(name: 'Name').attributes)
        .to match('id' => nil, 'full_name' => 'Name', 'author' => nil, 'projects' => nil)
    end

    specify do
      expect(model.new(name: 'Name').attributes(false))
        .to match('id' => nil, 'full_name' => 'Name')
    end
  end

  describe '#assign_attributes' do
    subject { model.new }

    let(:attributes) { { id: 42, full_name: 'Name', missed: 'value' } }

    specify { expect { subject.assign_attributes(attributes) }.to change { subject.id }.to(42) }
    specify { expect { subject.assign_attributes(attributes) }.to change { subject.full_name }.to('Name') }

    context 'features stack and assign order' do
      subject { model.new }

      let(:model) do
        stub_model do
          attr_reader :logger

          def self.log(a)
            define_method("#{a}=") do |*args|
              log(a)
              super(*args)
            end
          end

          def log(o)
            (@logger ||= []).push(o)
          end

          attribute :plain1, String
          attribute :plain2, String
          log(:plain1)
          log(:plain2)
        end
      end

      specify do
        expect { subject.assign_attributes(plain1: 'value', plain2: 'value') }
          .to change { subject.logger }.to(%i[plain1 plain2])
      end

      specify do
        expect { subject.assign_attributes(plain2: 'value', plain1: 'value') }
          .to change { subject.logger }.to(%i[plain2 plain1])
      end

      context do
        before do
          model.class_eval do
            include Granite::Form::Model::Representation
            include Granite::Form::Model::Associations

            embeds_one :assoc do
              attribute :assoc_plain, String
            end
            accepts_nested_attributes_for :assoc

            represents :assoc_plain, of: :assoc

            log(:assoc_attributes)
            log(:assoc_plain)

            def assign_attributes(attrs)
              super(attrs.merge(attrs.extract!('plain2')))
            end
          end
        end

        specify do
          expect do
            subject.assign_attributes(assoc_plain: 'value', assoc_attributes: {}, plain1: 'value', plain2: 'value')
          end
            .to change { subject.logger }.to(%i[plain1 assoc_attributes assoc_plain plain2])
        end

        specify do
          expect do
            subject.assign_attributes(plain1: 'value', plain2: 'value', assoc_plain: 'value', assoc_attributes: {})
          end
            .to change { subject.logger }.to(%i[plain1 assoc_attributes assoc_plain plain2])
        end
      end
    end
  end

  describe '#sync_attributes' do
    before do
      stub_class :author, ActiveRecord::Base do
        alias_attribute :full_name, :name
      end

      stub_model :model do
        include Granite::Form::Model::Dirty
        include Granite::Form::Model::Representation

        attribute :age, Integer
        attribute :author, Author
        represents :name, :full_name, of: :author
      end
    end

    let(:author) { Author.new }
    let(:model) { Model.new(attributes) }
    let(:attributes) { { author: author, name: 'Author Name', full_name: nil, age: 25 } }

    it { expect { model.sync_attributes }.to change(author, :name).to('Author Name') }

    context 'with aliased attribute' do
      let(:attributes) { super().merge(name: nil, full_name: 'Name Alias') }

      it { expect { model.sync_attributes }.to change(author, :name).to('Name Alias') }
    end
  end

  describe '#inspect' do
    specify { expect(stub_model.new.inspect).to match(/#<#<Class:0x\w+> \(no attributes\)>/) }
    specify { expect(stub_model(:user).new.inspect).to match(/#<User \(no attributes\)>/) }

    specify do
      expect(stub_model do
               include Granite::Form::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.new(object: 'String').inspect).to match(/#<#<Class:0x\w+> \*count: nil, object: "String">/)
    end

    specify do
      expect(stub_model(:user) do
               include Granite::Form::Model::Primary
               primary :count, Integer
               attribute :object, Object
             end.new.inspect).to match(/#<User \*count: nil, object: nil>/)
    end
  end

  context 'attributes integration' do
    subject { model.new('world') }

    let(:model) do
      stub_class do
        include Granite::Form::Util
        include Granite::Form::Model::Attributes
        include Granite::Form::Model::Associations
        attr_accessor :name

        attribute :id, Integer
        attribute :hello, Object
        attribute :string, String, default: -> { name }
        attribute :count, Integer, default: '10'
        attribute(:calc, Integer) { 2 + 3 }
        attribute :enum, Integer, enum: [1, 2, 3]
        attribute :enum_with_default, Integer, enum: [1, 2, 3], default: '2'
        attribute :foo, Boolean, default: false
        collection :array, Integer, enum: [1, 2, 3], default: [2], normalizer: ->(v) { v.uniq }
        dictionary :dict, Integer, keys: %w[from to], enum: [1, 2, 3], default: { from: 1 }, normalizer: proc { |v|
          next v if v[:from].nil? || v[:to].nil? || v[:from] <= v[:to]

          { from: v[:to], to: v[:from] }.with_indifferent_access
        }

        def initialize(name = nil)
          super()
          @name = name
        end
      end
    end

    its(:enum_values) { is_expected.to eq [1, 2, 3] }
    its(:string_default) { is_expected.to eq 'world' }
    its(:count_default) { is_expected.to eq '10' }
    its(:name) { is_expected.to eq 'world' }
    its(:hello) { is_expected.to eq(nil) }
    its(:hello?) { is_expected.to eq(false) }
    its(:count) { is_expected.to eq 10 }
    its(:count_before_type_cast) { is_expected.to eq '10' }
    its(:count_came_from_user?) { is_expected.to eq(false) }
    its(:count?) { is_expected.to eq(true) }
    its(:calc) { is_expected.to eq 5 }
    its(:enum?) { is_expected.to eq(false) }
    its(:enum_with_default?) { is_expected.to eq(true) }
    specify { expect { subject.hello = 'worlds' }.to change { subject.hello }.from(nil).to('worlds') }
    specify { expect { subject.count = 20 }.to change { subject.count }.from(10).to(20) }
    specify { expect { subject.calc = 15 }.to change { subject.calc }.from(5).to(15) }
    specify { expect { subject.count = '11' }.to change { subject.count_came_from_user? }.from(false).to(true) }

    context 'enums' do
      specify do
        subject.enum = 3
        expect(subject.enum).to eq(3)
      end

      specify do
        subject.enum = '3'
        expect(subject.enum).to eq(3)
      end

      specify do
        subject.enum = 10
        expect(subject.enum).to eq(nil)
      end

      specify do
        subject.enum = 'hello'
        expect(subject.enum).to eq(nil)
      end

      specify do
        subject.enum_with_default = 3
        expect(subject.enum_with_default).to eq(3)
      end

      specify do
        subject.enum_with_default = 10
        expect(subject.enum_with_default).to be_nil
      end
    end

    describe 'array' do
      def with_assigned_value(value)
        subject.array = value
        expect(subject)
      end

      specify do
        expect(subject).to have_attributes(
          array: [2],
          array_before_type_cast: [2],
          array?: true,
          array_default: [2],
          array_values: [1, 2, 3]
        )
      end

      specify { with_assigned_value(nil).to have_attributes(array: [2], array_before_type_cast: [2]) }
      specify { with_assigned_value([nil]).to have_attributes(array: [nil], array_before_type_cast: [nil]) }
      specify { with_assigned_value(1).to have_attributes(array: [1], array_before_type_cast: 1) }
      specify { with_assigned_value([1, 2]).to have_attributes(array: [1, 2], array_before_type_cast: [1, 2]) }
      specify { with_assigned_value([2, 4]).to have_attributes(array: [2, nil], array_before_type_cast: [2, 4]) }
      specify { with_assigned_value(%w[1 2]).to have_attributes(array: [1, 2], array_before_type_cast: %w[1 2]) }
      specify { with_assigned_value([1, 2, 1]).to have_attributes(array: [1, 2], array_before_type_cast: [1, 2, 1]) }
    end

    describe 'dict' do
      def with_assigned_value(value)
        subject.dict = value
        expect(subject)
      end

      specify do
        expect(subject).to have_attributes(
          dict: { from: 1 },
          dict_before_type_cast: { from: 1 },
          dict?: true,
          dict_default: { from: 1 },
          dict_values: [1, 2, 3]
        )
      end

      specify { with_assigned_value(nil).to have_attributes(dict: { 'from' => 1 }, dict_before_type_cast: { from: 1 }) }
      specify { with_assigned_value([nil]).to have_attributes(dict: {}, dict_before_type_cast: [nil]) }
      specify { with_assigned_value(1).to have_attributes(dict: {}, dict_before_type_cast: 1) }

      specify do
        with_assigned_value(from: 1, to: 2)
          .to have_attributes(dict: { 'from' => 1, 'to' => 2 }, dict_before_type_cast: { from: 1, to: 2 })
      end

      specify do
        with_assigned_value(from: 2, to: 4)
          .to have_attributes(dict: { 'from' => 2, 'to' => nil }, dict_before_type_cast: { from: 2, to: 4 })
      end

      specify do
        with_assigned_value(from: '1', to: '2')
          .to have_attributes(dict: { 'from' => 1, 'to' => 2 }, dict_before_type_cast: { from: '1', to: '2' })
      end

      specify do
        with_assigned_value(from: 3, to: 1)
          .to have_attributes(dict: { 'from' => 1, 'to' => 3 }, dict_before_type_cast: { from: 3, to: 1 })
      end
    end

    context 'attribute caching' do
      before do
        subject.hello = 'blabla'
        subject.hello
        subject.hello = 'newnewnew'
      end

      specify { expect(subject.hello).to eq('newnewnew') }
    end
  end

  context 'inheritance' do
    let!(:ancestor) do
      Class.new do
        include Granite::Form::Model::Attributes
        attribute :foo, String
      end
    end

    let!(:descendant1) do
      Class.new ancestor do
        attribute :bar, String
      end
    end

    let!(:descendant2) do
      Class.new ancestor do
        attribute :baz, String
        attribute :moo, String
      end
    end

    specify { expect(ancestor._attributes.keys).to eq(['foo']) }
    specify { expect(ancestor.instance_methods).to include :foo, :foo= }
    specify { expect(ancestor.instance_methods).not_to include :bar, :bar=, :baz, :baz= }
    specify { expect(descendant1._attributes.keys).to eq(%w[foo bar]) }
    specify { expect(descendant1.instance_methods).to include :foo, :foo=, :bar, :bar= }
    specify { expect(descendant1.instance_methods).not_to include :baz, :baz= }
    specify { expect(descendant2._attributes.keys).to eq(%w[foo baz moo]) }
    specify { expect(descendant2.instance_methods).to include :foo, :foo=, :baz, :baz=, :moo, :moo= }
    specify { expect(descendant2.instance_methods).not_to include :bar, :bar= }
  end
end
