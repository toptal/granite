require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::Reflections::ReferencesMany do
  before do
    stub_class(:author, ActiveRecord::Base) do
      scope :name_starts_with_a, -> { name_starts_with('a') }
      scope :name_starts_with, ->(letter) { where("name ILIKE '#{letter}%'") }
    end

    stub_model(:book) do
      include Granite::Form::Model::Associations

      attribute :title, String
      references_many :authors
    end
  end

  let(:author) { Author.create!(name: 'Rick') }
  let(:other) { Author.create!(name: 'John') }
  let(:book) { Book.new }
  let(:book_with_author) { Book.new(authors: [author]) }

  specify { expect(book.authors).to be_empty }

  context ':class_name' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations

        attribute :title, String
        references_many :creators, class_name: 'Author'
      end
    end

    let(:book) { Book.new }

    specify do
      expect { book.creators << author }
        .to change { book.creators }.from([]).to([author])
    end

    specify do
      expect { book.creators << author }
        .to change { book.creator_ids }.from([]).to([author.id])
    end
  end

  describe ':primary_key' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        collection :author_names, String
        references_many :authors, primary_key: 'name'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }

    specify do
      expect { book.author_names = [author.name] }
        .to change { book.authors }.from([]).to([author])
    end

    specify do
      expect { book.authors = [author] }
        .to change { book.author_names }.from([]).to([author.name])
    end
  end

  describe ':reference_key' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        references_many :authors, reference_key: 'identify'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }

    specify do
      expect { book.identify = [author.id] }
        .to change { book.authors }.from([]).to([author])
    end

    specify do
      expect { book.authors = [author] }
        .to change { book.identify }.from([]).to([author.id])
    end
  end

  describe ':default' do
    shared_examples_for 'persisted default' do |default|
      before do
        stub_model(:book) do
          include Granite::Form::Model::Associations
          references_many :authors
          references_many :owners, class_name: 'Author', default: default
        end
      end

      let(:author) { Author.create! }
      let(:other) { Author.create! }
      let(:book) { Book.new(authors: [author]) }

      specify { expect(book.owner_ids).to eq([author.id]) }
      specify { expect(book.owners).to eq([author]) }
      specify { expect { book.owners = [other] }.to change { book.owner_ids }.from([author.id]).to([other.id]) }
      specify { expect { book.owners = [other] }.to change { book.owners }.from([author]).to([other]) }
      specify { expect { book.owner_ids = [other.id] }.to change { book.owner_ids }.from([author.id]).to([other.id]) }
      specify { expect { book.owner_ids = [other.id] }.to change { book.owners }.from([author]).to([other]) }
      specify { expect { book.owners = [] }.to change { book.owner_ids }.from([author.id]).to([]) }
      specify { expect { book.owners = [] }.to change { book.owners }.from([author]).to([]) }
      specify { expect { book.owner_ids = [] }.not_to change { book.owner_ids }.from([author.id]) }
      specify { expect { book.owner_ids = [] }.not_to change { book.owners }.from([author]) }
      specify { expect { book.owner_ids = [nil] }.to change { book.owner_ids }.from([author.id]).to([]) }
      specify { expect { book.owner_ids = [nil] }.to change { book.owners }.from([author]).to([]) }
      specify { expect { book.owner_ids = [''] }.to change { book.owner_ids }.from([author.id]).to([]) }
      specify { expect { book.owner_ids = [''] }.to change { book.owners }.from([author]).to([]) }
      specify { expect { book.owner_ids = nil }.not_to change { book.owner_ids }.from([author.id]) }
      specify { expect { book.owner_ids = nil }.not_to change { book.owners }.from([author]) }
      specify { expect { book.owner_ids = '' }.to change { book.owner_ids }.from([author.id]).to([]) }
      specify { expect { book.owner_ids = '' }.to change { book.owners }.from([author]).to([]) }
    end

    it_behaves_like 'persisted default', -> { authors.map(&:id) }
    it_behaves_like 'persisted default', -> { authors }

    shared_examples_for 'new record default' do |default|
      before do
        stub_model(:book) do
          include Granite::Form::Model::Associations
          references_many :authors
          references_many :owners, class_name: 'Author', default: default
        end
      end

      let(:author) { Author.create! }
      let(:book) { Book.new }

      specify { expect(book.owner_ids).to eq([nil]) }
      specify { expect(book.owners).to match([an_instance_of(Author).and(have_attributes(name: 'Author'))]) }
      specify { expect { book.owners = [other] }.to change { book.owner_ids }.from([nil]).to([other.id]) }
      specify { expect { book.owners = [other] }.to change { book.owners }.from([an_instance_of(Author)]).to([other]) }
      specify { expect { book.owner_ids = [other.id] }.to change { book.owner_ids }.from([nil]).to([other.id]) }

      specify do
        expect { book.owner_ids = [other.id] }
          .to change { book.owners }
          .from([an_instance_of(Author)])
          .to([other])
      end

      specify { expect { book.owners = [] }.to change { book.owner_ids }.from([nil]).to([]) }
      specify { expect { book.owners = [] }.to change { book.owners }.from([an_instance_of(Author)]).to([]) }
      specify { expect { book.owner_ids = [] }.not_to change { book.owner_ids }.from([nil]) }
      specify { expect { book.owner_ids = [] }.not_to change { book.owners }.from([an_instance_of(Author)]) }
      specify { expect { book.owner_ids = [nil] }.to change { book.owner_ids }.from([nil]).to([]) }
      specify { expect { book.owner_ids = [nil] }.to change { book.owners }.from([an_instance_of(Author)]).to([]) }
      specify { expect { book.owner_ids = [''] }.to change { book.owner_ids }.from([nil]).to([]) }
      specify { expect { book.owner_ids = [''] }.to change { book.owners }.from([an_instance_of(Author)]).to([]) }
      specify { expect { book.owner_ids = nil }.not_to change { book.owner_ids }.from([nil]) }
      specify { expect { book.owner_ids = nil }.not_to change { book.owners }.from([an_instance_of(Author)]) }
      specify { expect { book.owner_ids = '' }.to change { book.owner_ids }.from([nil]).to([]) }
      specify { expect { book.owner_ids = '' }.to change { book.owners }.from([an_instance_of(Author)]).to([]) }
    end

    it_behaves_like 'new record default', name: 'Author'
    it_behaves_like 'new record default', -> { Author.new(name: 'Author') }
  end

  describe 'Book.inspect' do
    specify do
      expect(Book.inspect).to eq('Book(authors: ReferencesMany(Author), title: String, author_ids: (reference))')
    end
  end

  describe '#scope' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        references_many :authors, ->(owner) { name_starts_with(owner.letter) }
        attribute :letter, String
      end
    end

    let(:book) { Book.new(letter: 'a') }
    let!(:author1) { Author.create!(name: 'Rick') }
    let!(:author2) { Author.create!(name: 'Aaron') }

    specify do
      expect { book.authors = [author1, author2] }
        .to change { book.authors }.from([]).to([author1, author2])
    end

    specify do
      expect { book.authors = [author1, author2] }
        .to change { book.author_ids }.from([]).to([author1.id, author2.id])
    end

    specify do
      expect { book.author_ids = [author1.id, author2.id] }
        .to change { book.authors }.from([]).to([author2])
    end

    specify do
      expect { book.author_ids = [author1.id, author2.id] }
        .to change { book.author_ids }.from([]).to([author2.id])
    end

    specify do
      expect { book.authors = [author1, author2] }
        .to change { book.authors.reload }.from([]).to([author2])
    end

    specify do
      expect { book.authors = [author1, author2] }
        .to change {
          book.authors.reload
          book.author_ids
        }.from([]).to([author2.id])
    end

    context do
      let(:book2) { Book.new(letter: 'r') }

      specify 'scope is not cached too much' do
        expect { book.author_ids = [author1.id, author2.id] }
          .to change { book.authors }.from([]).to([author2])
        expect { book2.author_ids = [author1.id, author2.id] }
          .to change { book2.authors }.from([]).to([author1])
      end
    end
  end

  describe '#author' do
    it { expect(book.authors).not_to respond_to(:build) }
    it { expect(book.authors).not_to respond_to(:create) }
    it { expect(book.authors).not_to respond_to(:create!) }

    describe '#clear' do
      it { expect { book_with_author.authors.clear }.to change { book_with_author.authors }.from([author]).to([]) }
    end

    describe '#reload' do
      before { book.authors << author.tap { |a| a.name = 'Don Juan' } }

      it { expect { book.authors.reload }.to change { book.authors.map(&:name) }.from(['Don Juan']).to(['Rick']) }
    end

    describe '#concat' do
      it { expect { book.authors.concat author }.to change { book.authors }.from([]).to([author]) }
      it { expect { book.authors << author << other }.to change { book.authors }.from([]).to([author, other]) }

      context 'no duplication' do
        before { book.authors << author }

        it { expect { book.authors.concat author }.not_to change { book.authors }.from([author]) }
      end
    end

    context 'scope missing method delegation' do
      it { expect(book_with_author.authors.scope).to be_a ActiveRecord::Relation }
      it { expect(book_with_author.authors.where(name: 'John')).to be_a ActiveRecord::Relation }
      it { expect(book_with_author.authors.name_starts_with_a).to be_a ActiveRecord::Relation }
    end
  end

  describe '#author_ids' do
    it { expect(book_with_author.author_ids).to eq([author.id]) }

    xit do
      expect { book_with_author.author_ids << other.id }
        .to change { book_with_author.authors }
        .from([author])
        .to([author, other])
    end

    it {
      expect { book_with_author.author_ids = [other.id] }
        .to change { book_with_author.authors }
        .from([author])
        .to([other])
    }
  end

  describe '#authors=' do
    specify { expect { book.authors = [author] }.to change { book.authors }.from([]).to([author]) }
    specify { expect { book.authors = ['string'] }.to raise_error Granite::Form::AssociationTypeMismatch }

    context do
      before { book.authors = [other] }

      specify { expect { book.authors = [author] }.to change { book.authors }.from([other]).to([author]) }
      specify { expect { book.authors = [author] }.to change { book.author_ids }.from([other.id]).to([author.id]) }
      specify { expect { book.authors = [] }.to change { book.authors }.from([other]).to([]) }
      specify { expect { book.authors = [] }.to change { book.author_ids }.from([other.id]).to([]) }
    end

    context 'model not persisted' do
      let(:author) { Author.new }

      specify { expect { book.authors = [author, other] }.to change { book.authors }.from([]).to([author, other]) }
      specify { expect { book.authors = [author, other] }.to change { book.author_ids }.from([]).to([nil, other.id]) }

      context do
        before { book.authors = [author, other] }

        specify do
          expect { author.save! }.to change { book.author_ids }.from([nil, other.id])
                                                               .to(match([be_a(Integer), other.id]))
        end

        specify { expect { author.save! }.not_to(change { book.authors }) }
      end
    end
  end

  describe '#author_ids=' do
    specify { expect { book.author_ids = [author.id] }.to change { book.author_ids }.from([]).to([author.id]) }
    specify { expect { book.author_ids = [author.id] }.to change { book.authors }.from([]).to([author]) }
    specify { expect { book.author_ids = [author] }.to change { book.authors }.from([]).to([author]) }

    specify { expect { book.author_ids = [author.id.next.to_s] }.not_to change { book.author_ids }.from([]) }
    specify { expect { book.author_ids = [author.id.next.to_s] }.not_to change { book.authors }.from([]) }

    specify do
      expect { book.author_ids = [author.id.next.to_s, author.id] }
        .to change { book.author_ids }
        .from([])
        .to([author.id])
    end

    specify do
      expect { book.author_ids = [author.id.next.to_s, author.id] }
        .to change { book.authors }
        .from([])
        .to([author])
    end

    context do
      before { book.authors = [other] }

      specify do
        expect { book.author_ids = [author.id] }
          .to change { book.author_ids }
          .from([other.id])
          .to([author.id])
      end

      specify { expect { book.author_ids = [author.id] }.to change { book.authors }.from([other]).to([author]) }
      specify { expect { book.author_ids = [] }.to change { book.author_ids }.from([other.id]).to([]) }
      specify { expect { book.author_ids = [] }.to change { book.authors }.from([other]).to([]) }
    end
  end
end
