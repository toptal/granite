require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::Reflections::ReferencesOne do
  before do
    stub_class(:author, ActiveRecord::Base) do
      scope :name_starts_with_a, -> { name_starts_with('a') }
      scope :name_starts_with, ->(letter) { where("name ILIKE '#{letter}%'") }
    end

    stub_model(:book) do
      include Granite::Form::Model::Associations

      attribute :title, String
      references_one :author
    end
  end

  let(:book) { Book.new }

  specify { expect(book.author).to be_nil }

  context ':class_name' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations

        attribute :title, String
        references_one :creator, class_name: 'Author'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }

    specify do
      expect { book.creator = author }
        .to change { book.creator }.from(nil).to(author)
    end

    specify do
      expect { book.creator = author }
        .to change { book.creator_id }.from(nil).to(author.id)
    end
  end

  describe ':primary_key' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        attribute :author_name, String
        references_one :author, primary_key: 'name'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }

    specify do
      expect { book.author_name = author.name }
        .to change { book.author }.from(nil).to(author)
    end

    specify do
      expect { book.author = author }
        .to change { book.author_name }.from(nil).to(author.name)
    end
  end

  describe ':reference_key' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        references_one :author, reference_key: 'identify'
      end
    end

    let(:author) { Author.create!(name: 'Rick') }

    specify do
      expect { book.identify = author.id }
        .to change { book.author }.from(nil).to(author)
    end

    specify do
      expect { book.author = author }
        .to change { book.identify }.from(nil).to(author.id)
    end
  end

  describe ':default' do
    shared_examples_for 'persisted default' do |default|
      before do
        stub_model(:book) do
          include Granite::Form::Model::Associations
          references_one :author
          references_one :owner, class_name: 'Author', default: default
        end
      end

      let(:author) { Author.create! }
      let(:other) { Author.create! }
      let(:book) { Book.new(author: author) }

      specify { expect(book.owner_id).to eq(author.id) }
      specify { expect(book.owner).to eq(author) }
      specify { expect { book.owner = other }.to change { book.owner_id }.from(author.id).to(other.id) }
      specify { expect { book.owner = other }.to change { book.owner }.from(author).to(other) }
      specify { expect { book.owner_id = other.id }.to change { book.owner_id }.from(author.id).to(other.id) }
      specify { expect { book.owner_id = other.id }.to change { book.owner }.from(author).to(other) }
      specify { expect { book.owner = nil }.to change { book.owner_id }.from(author.id).to(nil) }
      specify { expect { book.owner = nil }.to change { book.owner }.from(author).to(nil) }
      specify { expect { book.owner_id = nil }.not_to change { book.owner_id }.from(author.id) }
      specify { expect { book.owner_id = nil }.not_to change { book.owner }.from(author) }
      specify { expect { book.owner_id = '' }.to change { book.owner_id }.from(author.id).to(nil) }
      specify { expect { book.owner_id = '' }.to change { book.owner }.from(author).to(nil) }
    end

    it_behaves_like 'persisted default', -> { author.id }
    it_behaves_like 'persisted default', -> { author }

    shared_examples_for 'new record default' do |default|
      before do
        stub_model(:book) do
          include Granite::Form::Model::Associations
          references_one :author
          references_one :owner, class_name: 'Author', default: default
        end
      end

      let(:other) { Author.create! }
      let(:book) { Book.new }

      specify { expect(book.owner_id).to be_nil }
      specify { expect(book.owner).to be_a(Author).and have_attributes(name: 'Author') }
      specify { expect { book.owner = other }.to change { book.owner_id }.from(nil).to(other.id) }
      specify { expect { book.owner = other }.to change { book.owner }.from(instance_of(Author)).to(other) }
      specify { expect { book.owner_id = other.id }.to change { book.owner_id }.from(nil).to(other.id) }
      specify { expect { book.owner_id = other.id }.to change { book.owner }.from(instance_of(Author)).to(other) }
      specify { expect { book.owner = nil }.not_to change { book.owner_id }.from(nil) }
      specify { expect { book.owner = nil }.to change { book.owner }.from(instance_of(Author)).to(nil) }
      specify { expect { book.owner_id = nil }.not_to change { book.owner_id }.from(nil) }
      specify { expect { book.owner_id = nil }.not_to change { book.owner }.from(instance_of(Author)) }
      specify { expect { book.owner_id = '' }.not_to change { book.owner_id }.from(nil) }
      specify { expect { book.owner_id = '' }.to change { book.owner }.from(instance_of(Author)).to(nil) }
    end

    it_behaves_like 'new record default', name: 'Author'
    it_behaves_like 'new record default', -> { Author.new(name: 'Author') }
  end

  describe 'Book.inspect' do
    specify { expect(Book.inspect).to eq('Book(author: ReferencesOne(Author), title: String, author_id: (reference))') }
  end

  describe '#scope' do
    before do
      stub_model(:book) do
        include Granite::Form::Model::Associations
        references_one :author, ->(owner) { name_starts_with(owner.letter) }
        attribute :letter, String
      end
    end

    let(:book) { Book.new(letter: 'a') }
    let!(:author1) { Author.create!(name: 'Rick') }
    let!(:author2) { Author.create!(name: 'Aaron') }

    specify do
      expect { book.author_id = author1.id }
        .not_to(change { book.author })
    end

    specify do
      expect { book.author_id = author2.id }
        .to change { book.author }.from(nil).to(author2)
    end

    specify do
      expect { book.author = author1 }
        .to change { book.author_id }.from(nil).to(author1.id)
    end

    specify do
      expect { book.author = author2 }
        .to change { book.author_id }.from(nil).to(author2.id)
    end

    specify do
      expect { book.author = author1 }
        .to change {
          book.association(:author).reload
          book.author_id
        }.from(nil).to(author1.id)
    end

    specify do
      expect { book.author = author2 }
        .to change {
          book.association(:author).reload
          book.author_id
        }.from(nil).to(author2.id)
    end

    specify do
      expect { book.author = author1 }
        .not_to(change do
          book.association(:author).reload
          book.author
        end)
    end

    specify do
      expect { book.author = author2 }
        .to change {
          book.association(:author).reload
          book.author
        }.from(nil).to(author2)
    end

    context do
      let(:book2) { Book.new(letter: 'r') }

      specify 'scope is not cached too much' do
        expect { book.author_id = author2.id }
          .to change { book.author }.from(nil).to(author2)
        expect { book2.author_id = author1.id }
          .to change { book2.author }.from(nil).to(author1)
      end
    end
  end

  describe '#author=' do
    let(:author) { Author.create! name: 'Author' }

    specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author = 'string' }.to raise_error Granite::Form::AssociationTypeMismatch }

    context do
      let(:other) { Author.create! name: 'Other' }

      before { book.author = other }

      specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author = author }.to change { book.author_id }.from(other.id).to(author.id) }
      specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
      specify { expect { book.author = nil }.to change { book.author_id }.from(other.id).to(nil) }
    end

    context 'model not persisted' do
      let(:author) { Author.new }

      specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
      specify { expect { book.author = author }.not_to change { book.author_id }.from(nil) }

      context do
        before { book.author = author }

        specify { expect { author.save! }.to change { book.author_id }.from(nil).to(be_a(Integer)) }
        specify { expect { author.save! }.not_to(change { book.author }) }
      end
    end
  end

  describe '#author_id=' do
    let(:author) { Author.create!(name: 'Author') }

    specify { expect { book.author_id = author.id }.to change { book.author_id }.from(nil).to(author.id) }
    specify { expect { book.author_id = author.id }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author_id = author }.to change { book.author }.from(nil).to(author) }

    specify do
      expect { book.author_id = author.id.next.to_s }
        .to change { book.author_id }
        .from(nil)
        .to(author.id.next)
    end

    specify { expect { book.author_id = author.id.next.to_s }.not_to change { book.author }.from(nil) }

    context do
      let(:other) { Author.create!(name: 'Other') }

      before { book.author = other }

      specify { expect { book.author_id = author.id }.to change { book.author_id }.from(other.id).to(author.id) }
      specify { expect { book.author_id = author.id }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author_id = nil }.to change { book.author_id }.from(other.id).to(nil) }
      specify { expect { book.author_id = nil }.to change { book.author }.from(other).to(nil) }
    end
  end
end
