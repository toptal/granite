require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::EmbedsOne do
  before do
    stub_model(:author) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :name, String
      validates :name, presence: true
    end

    stub_model(:book) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :title, String
      embeds_one :author
    end
  end

  let(:book) { Book.new(title: 'Book') }
  let(:association) { book.association(:author) }

  let(:existing_book) { Book.instantiate title: 'My Life', author: { 'name' => 'Johny' } }
  let(:existing_association) { existing_book.association(:author) }

  context 'callbacks' do
    before do
      Book.class_eval do
        embeds_one :author, before_add: :before_add, after_add: :after_add

        def before_add(object)
          callbacks.push([:before_add, object])
        end

        def after_add(object)
          callbacks.push([:after_add, object])
        end

        collection :callbacks, Array
      end
    end

    let(:author1) { Author.new(name: 'Author1') }
    let(:author2) { Author.new(name: 'Author2') }

    specify do
      expect { association.build(name: 'Author1') }
        .to change { book.callbacks }
        .to([[:before_add, author1], [:after_add, author1]])
    end

    specify do
      expect do
        association.build(name: 'Author1')
        association.build(name: 'Author2')
      end
        .to change { book.callbacks }
        .to([
              [:before_add, author1], [:after_add, author1],
              [:before_add, author2], [:after_add, author2]
            ])
    end

    specify do
      expect { association.writer(author1) }
        .to change { book.callbacks }
        .to([[:before_add, author1], [:after_add, author1]])
    end

    specify do
      expect do
        association.writer(author1)
        association.writer(nil)
        association.writer(author1)
      end
        .to change { book.callbacks }
        .to([
              [:before_add, author1], [:after_add, author1],
              [:before_add, author1], [:after_add, author1]
            ])
    end

    context 'default' do
      before do
        Book.class_eval do
          embeds_one :author,
                     before_add: ->(object) { callbacks.push([:before_add, object]) },
                     after_add: ->(object) { callbacks.push([:after_add, object]) },
                     default: -> { { name: 'Author1' } }

          collection :callbacks, Array
        end
      end

      specify do
        expect { association.writer(author2) }
          .to change { book.callbacks }
          .to([
                [:before_add, author1], [:after_add, author1],
                [:before_add, author2], [:after_add, author2]
              ])
      end
    end
  end

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:author)) }
  end

  describe 'author#embedder' do
    let(:author) { Author.new(name: 'Author') }

    specify { expect(association.build.embedder).to eq(book) }

    specify do
      expect { association.writer(author) }
        .to change { author.embedder }.from(nil).to(book)
    end

    specify do
      expect { association.target = author }
        .to change { author.embedder }.from(nil).to(book)
    end

    context 'default' do
      before do
        Book.class_eval do
          embeds_one :author, default: -> { { name: 'Author1' } }
        end
      end

      specify { expect(association.target.embedder).to eq(book) }

      context do
        before do
          Book.class_eval do
            embeds_one :author, default: -> { Author.new(name: 'Author1') }
          end
        end

        specify { expect(association.target.embedder).to eq(book) }
      end
    end

    context 'embedding goes before attributes' do
      before do
        Author.class_eval do
          attribute :name, String, normalize: ->(value) { "#{value}#{embedder.title}" }
        end
      end

      specify { expect(association.build(name: 'Author').name).to eq('AuthorBook') }
    end
  end

  describe '#build' do
    specify { expect(association.build).to be_a Author }
    specify { expect(association.build).not_to be_persisted }

    specify do
      expect { association.build(name: 'Fred') }
        .not_to(change { book.read_attribute(:author) })
    end

    specify do
      expect { existing_association.build(name: 'Fred') }
        .not_to(change { existing_book.read_attribute(:author) })
    end
  end

  describe '#target' do
    specify { expect(association.target).to be_nil }
    specify { expect(existing_association.target).to eq(existing_book.author) }
    specify { expect { association.build }.to change { association.target }.to(an_instance_of(Author)) }
  end

  describe '#default' do
    before do
      Book.embeds_one :author, default: -> { { name: 'Default' } }
      Author.class_eval do
        include Granite::Form::Model::Primary
        primary :name
      end
    end

    let(:new_author) { Author.new.tap { |a| a.name = 'Morty' } }
    let(:existing_book) { Book.instantiate title: 'My Life' }

    specify { expect(association.target.name).to eq('Default') }
    specify { expect(association.target.new_record?).to eq(true) }
    specify { expect { association.replace(new_author) }.to change { association.target.name }.to eq('Morty') }
    specify { expect { association.replace(nil) }.to change { association.target }.to be_nil }

    specify { expect(existing_association.target).to be_nil }

    specify do
      expect { existing_association.replace(new_author) }
        .to change { existing_association.target }
        .to(an_instance_of(Author))
    end

    specify { expect { existing_association.replace(nil) }.not_to(change { existing_association.target }) }

    context do
      before { Author.include Granite::Form::Model::Dirty }

      specify { expect(association.target).not_to be_changed }
    end
  end

  describe '#loaded?' do
    let(:new_author) { Author.new(name: 'Morty') }

    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
    specify { expect { association.build }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(new_author) }.to change { association.loaded? }.to(true) }
    specify { expect { association.replace(nil) }.to change { association.loaded? }.to(true) }
    specify { expect { existing_association.replace(new_author) }.to change { existing_association.loaded? }.to(true) }
    specify { expect { existing_association.replace(nil) }.to change { existing_association.loaded? }.to(true) }
  end

  describe '#reload' do
    specify { expect(association.reload).to be_nil }

    specify { expect(existing_association.reload).to be_a Author }
    specify { expect(existing_association.reload).to be_persisted }

    context do
      before { association.build(name: 'Fred') }

      specify do
        expect { association.reload }
          .to change { association.reader.try(:attributes) }.from('name' => 'Fred').to(nil)
      end
    end

    context do
      before { existing_association.build(name: 'Fred') }

      specify do
        expect { existing_association.reload }
          .to change { existing_association.reader.try(:attributes) }
          .from('name' => 'Fred').to('name' => 'Johny')
      end
    end
  end

  describe '#sync' do
    let!(:author) { association.build(name: 'Fred') }

    specify { expect { association.sync }.to change { book.read_attribute(:author) }.from(nil).to('name' => 'Fred') }

    context 'when embedding is nested' do
      before do
        Author.class_eval do
          include Granite::Form::Model::Associations

          embeds_many :reviews do
            attribute :rating, Integer
          end
        end

        author.reviews.build(rating: 7)
      end

      specify do
        expect { association.sync }.to change { book.read_attribute(:author) }
          .from(nil).to('name' => 'Fred', 'reviews' => [{ 'rating' => 7 }])
      end
    end
  end

  describe '#clear' do
    specify { expect(association.clear).to eq(true) }
    specify { expect { association.clear }.not_to(change { association.reader }) }

    specify { expect(existing_association.clear).to eq(true) }

    specify do
      expect { existing_association.clear }
        .to change { existing_association.reader.try(:attributes) }.from('name' => 'Johny').to(nil)
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to be_nil }

    specify { expect(existing_association.reader).to be_a Author }
    specify { expect(existing_association.reader).to be_persisted }

    context do
      before { association.build }

      specify { expect(association.reader).to be_a Author }
      specify { expect(association.reader).not_to be_persisted }
      specify { expect(association.reader(true)).to be_nil }
    end

    context do
      before { existing_association.build(name: 'Fred') }

      specify { expect(existing_association.reader.name).to eq('Fred') }
      specify { expect(existing_association.reader(true).name).to eq('Johny') }
    end
  end

  describe '#writer' do
    let(:new_author) { Author.new(name: 'Morty') }
    let(:invalid_author) { Author.new }

    context 'new owner' do
      let(:book) do
        Book.new.tap do |book|
          book.send(:mark_persisted!)
        end
      end

      specify do
        expect { association.writer(nil) }
          .not_to(change { book.read_attribute(:author) })
      end

      specify do
        expect { association.writer(new_author) }
          .to change { association.reader.try(:attributes) }.from(nil).to('name' => 'Morty')
      end
    end

    context 'persisted owner' do
      specify do
        expect { association.writer(stub_model(:dummy).new) }
          .to raise_error Granite::Form::AssociationTypeMismatch
      end

      specify { expect(association.writer(nil)).to be_nil }
      specify { expect(association.writer(new_author)).to eq(new_author) }

      specify do
        expect { association.writer(new_author) }
          .to change { association.reader.try(:attributes) }.from(nil).to('name' => 'Morty')
      end

      specify do
        expect { association.writer(invalid_author) }
          .to change { association.reader.try(:attributes) }.from(nil).to('name' => nil)
      end

      specify do
        expect do
          muffle(Granite::Form::AssociationTypeMismatch) do
            existing_association.writer(stub_model(:dummy).new)
          end
        end
          .not_to(change { existing_association.reader })
      end

      specify { expect(existing_association.writer(nil)).to be_nil }
      specify { expect(existing_association.writer(new_author)).to eq(new_author) }

      specify do
        expect { existing_association.writer(new_author) }
          .to change { existing_association.reader.try(:attributes) }
          .from('name' => 'Johny').to('name' => 'Morty')
      end
    end
  end
end
