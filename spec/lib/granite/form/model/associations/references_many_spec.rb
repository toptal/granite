require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::ReferencesMany do
  before do
    stub_model_granite_form(:dummy)
    stub_class_granite_form(:author, ActiveRecord::Base) do
      scope :name_starts_with_a, -> { where('name ILIKE "a%"') }

      validates :name, presence: true
    end

    stub_model_granite_form(:book) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :title, String
      references_many :authors
    end
  end

  let(:author) { Author.create!(name: 'Rick') }
  let(:other) { Author.create!(name: 'Ben') }

  let(:book) { Book.new }
  let(:association) { book.association(:authors) }

  let(:existing_book) { Book.instantiate title: 'Genesis', author_ids: [author.id] }
  let(:existing_association) { existing_book.association(:authors) }

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:authors)) }
  end

  describe 'book#inspect' do
    specify { expect(existing_book.inspect).to eq(<<~STR.chomp) }
      #<Book authors: #<ReferencesMany #{[author].inspect.truncate(50, omission: '...]')}>, title: "Genesis", author_ids: [#{author.id}]>
    STR
  end

  describe '#scope' do
    specify { expect(association.scope).to be_a ActiveRecord::Relation }
    specify { expect(association.scope).to respond_to(:where) }
    specify { expect(association.scope).to respond_to(:name_starts_with_a) }
  end

  describe '#target' do
    specify { expect(association.target).to eq([]) }
    specify { expect(existing_association.target).to eq(existing_book.authors) }
    specify { expect { association.concat author }.to change { association.target.count }.to(1) }
  end

  describe '#default' do
    before { Book.references_many :authors, default: ->(_book) { author.id } }

    let(:existing_book) { Book.instantiate title: 'Genesis' }

    specify { expect(association.target).to eq([author]) }
    specify { expect { association.replace([other]) }.to change { association.target }.to([other]) }
    specify { expect { association.replace([]) }.to change { association.target }.to eq([]) }

    specify { expect(existing_association.target).to eq([]) }
    specify { expect { existing_association.replace([other]) }.to change { existing_association.target }.to([other]) }
    specify { expect { existing_association.replace([]) }.not_to(change { existing_association.target }) }
  end

  describe '#loaded?' do
    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace([]) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace([]) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to eq([]) }

    specify { expect(existing_association.reload).to eq(existing_book.authors) }

    context do
      before { existing_association.reader.last.name = 'Conan' }

      specify do
        expect { existing_association.reload }
          .to change { existing_association.reader.map(&:name) }
          .from(['Conan']).to(['Rick'])
      end
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to eq([]) }

    specify do
      expect(association.reader)
        .to be_a Granite::Form::Model::Associations::PersistenceAdapters::ActiveRecord::ReferencedProxy
    end

    specify { expect(existing_association.reader.first).to be_a Author }
    specify { expect(existing_association.reader.first).to be_persisted }

    context do
      before { association.concat author }

      specify { expect(association.reader.last).to be_a Author }
      specify { expect(association.reader.size).to eq(1) }
      specify { expect(association.reader(true)).to eq([author]) }
    end

    context do
      before { existing_association.concat other }

      specify { expect(existing_association.reader.size).to eq(2) }
      specify { expect(existing_association.reader.last.name).to eq('Ben') }
      specify { expect(existing_association.reader(true).size).to eq(2) }
      specify { expect(existing_association.reader(true).last.name).to eq('Ben') }
    end

    context 'proxy missing method delection' do
      specify { expect(existing_association.reader).to respond_to(:where) }
      specify { expect(existing_association.reader).to respond_to(:name_starts_with_a) }
    end
  end

  describe '#writer' do
    let(:new_author1) { Author.create!(name: 'John') }
    let(:new_author2) { Author.create!(name: 'Adam') }
    let(:new_author3) { Author.new(name: 'Jane') }

    specify do
      expect { association.writer([Dummy.new]) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify { expect { association.writer(nil) }.to raise_error NoMethodError }
    specify { expect { association.writer(new_author1) }.to raise_error NoMethodError }
    specify { expect(association.writer([])).to eq([]) }

    specify { expect(association.writer([new_author1])).to eq([new_author1]) }

    specify do
      expect { association.writer([new_author1]) }
        .to change { association.reader.map(&:name) }.from([]).to(['John'])
    end

    specify do
      expect { association.writer([new_author1]) }
        .to change { book.read_attribute(:author_ids) }
        .from([]).to([new_author1.id])
    end

    specify do
      expect { existing_association.writer([new_author1, Dummy.new, new_author2]) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.writer([new_author1, Dummy.new, new_author2])
        end
      end
        .not_to(change { existing_book.read_attribute(:author_ids) })
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.writer([new_author1, Dummy.new, new_author2])
        end
      end
        .not_to(change { existing_association.reader })
    end

    specify { expect { existing_association.writer(nil) }.to raise_error NoMethodError }

    specify do
      expect { muffle(NoMethodError) { existing_association.writer(nil) } }
        .not_to(change { existing_book.read_attribute(:author_ids) })
    end

    specify do
      expect { muffle(NoMethodError) { existing_association.writer(nil) } }
        .not_to(change { existing_association.reader })
    end

    specify { expect(existing_association.writer([])).to eq([]) }

    specify do
      expect { existing_association.writer([]) }
        .to change { existing_book.read_attribute(:author_ids) }.to([])
    end

    # specify do
    #   expect { existing_association.writer([]) }
    #     .to change { existing_association.reader }.from([author]).to([])
    # end

    specify { expect(existing_association.writer([new_author1, new_author2])).to eq([new_author1, new_author2]) }

    specify do
      expect { existing_association.writer([new_author1, new_author2]) }
        .to change { existing_association.reader.map(&:name) }
        .from(['Rick']).to(%w[John Adam])
    end

    specify do
      expect { existing_association.writer([new_author1, new_author2]) }
        .to change { existing_book.read_attribute(:author_ids) }
        .from([author.id]).to([new_author1.id, new_author2.id])
    end

    specify do
      expect { existing_association.writer([new_author3]) }
        .to change { existing_association.target }.from([author]).to([new_author3])
    end

    specify do
      expect { existing_association.writer([new_author3]) }
        .to change { existing_book.read_attribute(:author_ids) }
        .from([author.id]).to([nil])
    end
  end

  describe '#concat' do
    let(:new_author1) { Author.create!(name: 'John') }
    let(:new_author2) { Author.create!(name: 'Adam') }

    specify do
      expect { association.concat(Dummy.new) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify { expect { association.concat(nil) }.to raise_error Granite::Form::AssociationTypeMismatch }
    specify { expect(association.concat([])).to eq([]) }
    specify { expect(existing_association.concat([])).to eq(existing_book.authors) }
    specify { expect(existing_association.concat).to eq(existing_book.authors) }

    specify { expect(association.concat(new_author1)).to eq([new_author1]) }

    specify do
      expect { association.concat(new_author1) }
        .to change { association.reader.map(&:name) }.from([]).to(['John'])
    end

    specify do
      expect { association.concat(new_author1) }
        .to change { book.read_attribute(:author_ids) }.from([]).to([new_author1.id])
    end

    specify do
      expect { existing_association.concat(new_author1, Dummy.new, new_author2) }
        .to raise_error Granite::Form::AssociationTypeMismatch
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.concat(new_author1, Dummy.new, new_author2)
        end
      end
        .to change { existing_book.read_attribute(:author_ids) }
        .from([author.id]).to([author.id, new_author1.id])
    end

    specify do
      expect do
        muffle(Granite::Form::AssociationTypeMismatch) do
          existing_association.concat(new_author1, Dummy.new, new_author2)
        end
      end
        .to change { existing_association.reader.map(&:name) }
        .from(['Rick']).to(%w[Rick John])
    end

    specify do
      expect(existing_association.concat(new_author1, new_author2))
        .to eq([author, new_author1, new_author2])
    end

    specify do
      expect { existing_association.concat([new_author1, new_author2]) }
        .to change { existing_association.reader.map(&:name) }
        .from(['Rick']).to(%w[Rick John Adam])
    end

    specify do
      expect { existing_association.concat([new_author1, new_author2]) }
        .to change { existing_book.read_attribute(:author_ids) }
        .from([author.id]).to([author.id, new_author1.id, new_author2.id])
    end
  end
end
