require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::PersistenceAdapters::ActiveRecord do
  subject(:adapter) { described_class.new(Author, primary_key, scope_proc) }

  before do
    stub_class_granite_form(:author, ActiveRecord::Base)
  end

  let(:primary_key) { :id }
  let(:scope_proc) { nil }

  describe '#build' do
    subject { adapter.build(name: name) }

    let(:name) { 'John Doe' }

    its(:name) { is_expected.to eq name }
    it { is_expected.to be_a Author }
  end

  describe '#find_one' do
    subject { adapter.find_one(nil, author.id) }

    let(:author) { Author.create }

    it { is_expected.to eq author }
  end

  describe '#find_all' do
    subject { adapter.find_all(nil, authors.map(&:id)) }

    let(:authors) { Array.new(2) { Author.create } }

    it { is_expected.to eq authors }
  end

  describe '#scope' do
    subject { adapter.scope(owner, source) }

    let(:authors) { ['John Doe', 'Sam Smith', 'John Smith'].map { |name| Author.create(name: name) } }
    let(:source) { authors[0..1].map(&:id) }
    let(:owner) { nil }

    it { is_expected.to be_a ActiveRecord::Relation }

    context 'without scope_proc' do
      it { is_expected.to eq Author.where(primary_key => source) }
    end

    context 'with scope_proc' do
      let(:scope_proc) { -> { where("name LIKE 'John%'") } }

      its(:to_a) { is_expected.to eq [Author.first] }
    end
  end

  describe '#primary_key_type' do
    subject { adapter.primary_key_type }

    it { is_expected.to eq Integer }
  end
end
