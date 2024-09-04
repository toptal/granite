# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Granite::Form::Model::Attributes::Reflections::Represents::BuildTypeDefinition do
  def build_type_definition(name = :name, **options)
    @reflection = Granite::Form::Model::Attributes::Reflections::Represents.new(name,
                                                                                options.reverse_merge(of: :author))
    described_class.new(owner, @reflection).call
  end

  def have_type(type)
    have_attributes(type: type, reflection: @reflection, owner: owner)
  end

  let(:owner) { Owner.new }

  before do
    stub_model :author
    stub_model(:owner) do
      def author
        @author ||= Author.new
      end
    end
  end

  it { expect(build_type_definition).to have_type(Object) }
  it { expect(build_type_definition(type: String)).to have_type(String) }

  context 'when defined in attribute' do
    before { Author.attribute :name, String }

    it { expect(build_type_definition).to have_type(String) }
    it { expect(build_type_definition(type: Integer)).to have_type(Integer) }
  end

  context 'when defined in represented attribute' do
    before do
      stub_model(:real_author) do
        attribute :name, Boolean
      end
      Author.class_eval do
        include Granite::Form::Model::Representation
        represents :name, of: :subject

        def subject
          @subject ||= RealAuthor.new
        end
      end
    end

    it { expect(build_type_definition).to have_type(Boolean) }
  end

  context 'when defined in references_many' do
    before do
      stub_class(:user, ActiveRecord::Base)
      Author.class_eval do
        include Granite::Form::Model::Associations
        references_many :users
      end
    end

    it do
      attribute = build_type_definition(:user_ids)
      expect(attribute).to be_a(Granite::Form::Types::Collection)
      expect(attribute.subtype_definition).to have_type(Integer)
    end
  end

  context 'when defined in collection' do
    before do
      Author.collection :users, String
    end

    it do
      attribute = build_type_definition(:users)
      expect(attribute).to be_a(Granite::Form::Types::Collection)
      expect(attribute.subtype_definition).to have_type(String)
    end
  end

  context 'when defined in dictionary' do
    before do
      Author.dictionary :numbers, Float
    end

    it do
      attribute = build_type_definition(:numbers)
      expect(attribute).to be_a(Granite::Form::Types::Dictionary)
      expect(attribute.subtype_definition).to have_type(Float)
    end
  end

  context 'when defined in ActiveRecord::Base' do
    before do
      stub_class(:author, ActiveRecord::Base) do
        alias_attribute :full_name, :name
      end
    end

    it { expect(build_type_definition).to have_type(String) }
    it { expect(build_type_definition(:status)).to have_type(Integer) }
    it { expect(build_type_definition(:full_name)).to have_type(String) }
    it { expect(build_type_definition(:unknown_attribute)).to have_type(Object) }

    it do
      attribute = build_type_definition(:related_ids)
      expect(attribute).to be_a(Granite::Form::Types::Collection)
      expect(attribute.subtype_definition).to have_type(Integer)
    end

    context 'with enum' do
      before do
        if ActiveRecord.gem_version >= Gem::Version.new('7.0')
          Author.enum :status, once: 1, many: 2
        else
          Author.enum status: %i[once many]
        end
      end

      it { expect(build_type_definition(:status)).to have_type(String) }
    end

    context 'with serialized attribute' do
      before { Author.serialize :data }

      it { expect(build_type_definition(:data)).to have_type(Object) }
    end
  end
end
