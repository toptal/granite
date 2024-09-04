require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::ReferencesOne do
  before do
    stub_class_granite_form(:author, ActiveRecord::Base) do
      validates :name, presence: true
    end

    stub_model_granite_form(:book) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :title, String
      references_one :author
    end
  end

  let(:author) { Author.create!(name: 'Johny') }
  let(:other) { Author.create!(name: 'Other') }
  let(:book) { Book.new }
  let(:association) { book.association(:author) }

  let(:existing_book) { Book.instantiate title: 'My Life', author_id: author.id }
  let(:existing_association) { existing_book.association(:author) }

  describe 'book#association' do
    specify { expect(association).to be_a described_class }
    specify { expect(association).to eq(book.association(:author)) }
  end

  describe 'book#inspect' do
    specify { expect(existing_book.inspect).to eq(<<~STR.chomp) }
      #<Book author: #<ReferencesOne #{author.inspect.truncate(50)}>, title: "My Life", author_id: #{author.id}>
    STR
  end

  describe '#target' do
    specify { expect(association.target).to be_nil }
    specify { expect(existing_association.target).to eq(existing_book.author) }
  end

  describe '#loaded?' do
    let(:new_author) { Author.create(name: 'Morty') }

    specify { expect(association.loaded?).to eq(false) }
    specify { expect { association.target }.to change { association.loaded? }.to(true) }
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
      before { existing_association.reader.name = 'New' }

      specify do
        expect { existing_association.reload }
          .to change { existing_association.reader.name }
          .from('New').to('Johny')
      end
    end
  end

  describe '#reader' do
    specify { expect(association.reader).to be_nil }

    specify { expect(existing_association.reader).to be_a Author }
    specify { expect(existing_association.reader).to be_persisted }
  end

  describe '#default' do
    before { Book.references_one :author, default: ->(_book) { author.id } }

    let(:existing_book) { Book.instantiate title: 'My Life' }

    specify { expect(association.target).to eq(author) }
    specify { expect { association.replace(other) }.to change { association.target }.to(other) }
    specify { expect { association.replace(nil) }.to change { association.target }.to be_nil }

    specify { expect(existing_association.target).to be_nil }
    specify { expect { existing_association.replace(other) }.to change { existing_association.target }.to(other) }
    specify { expect { existing_association.replace(nil) }.not_to(change { existing_association.target }) }
  end

  describe '#writer' do
    context 'new owner' do
      let(:new_author) { Author.new(name: 'Morty') }

      let(:book) do
        Book.new.tap do |book|
          book.send(:mark_persisted!)
        end
      end

      specify do
        expect { association.writer(nil) }
          .not_to(change { book.author_id })
      end

      specify do
        expect { association.writer(new_author) }
          .to change { muffle(NoMethodError) { association.reader.name } }
          .from(nil).to('Morty')
      end

      specify do
        expect { association.writer(new_author) }
          .not_to change { book.author_id }.from(nil)
      end
    end

    context 'persisted owner' do
      let(:new_author) { Author.create!(name: 'Morty') }

      specify do
        expect { association.writer(stub_model_granite_form(:dummy).new) }
          .to raise_error Granite::Form::AssociationTypeMismatch
      end

      specify { expect(association.writer(nil)).to be_nil }
      specify { expect(association.writer(new_author)).to eq(new_author) }

      specify do
        expect { association.writer(nil) }
          .not_to(change { book.read_attribute(:author_id) })
      end

      specify do
        expect { association.writer(new_author) }
          .to change { association.reader }.from(nil).to(new_author)
      end

      specify do
        expect { association.writer(new_author) }
          .to(change { book.read_attribute(:author_id) })
      end

      context do
        before do
          stub_class_granite_form(:dummy, ActiveRecord::Base) do
            self.table_name = :authors
          end
        end

        specify do
          expect { muffle(Granite::Form::AssociationTypeMismatch) { existing_association.writer(Dummy.new) } }
            .not_to(change { existing_book.read_attribute(:author_id) })
        end

        specify do
          expect { muffle(Granite::Form::AssociationTypeMismatch) { existing_association.writer(Dummy.new) } }
            .not_to(change { existing_association.reader })
        end
      end

      specify { expect(existing_association.writer(nil)).to be_nil }
      specify { expect(existing_association.writer(new_author)).to eq(new_author) }

      specify do
        expect { existing_association.writer(nil) }
          .to change { existing_book.read_attribute(:author_id) }
          .from(author.id).to(nil)
      end

      specify do
        expect { existing_association.writer(new_author) }
          .to change { existing_association.reader }
          .from(author).to(new_author)
      end

      specify do
        expect { existing_association.writer(new_author) }
          .to change { existing_book.read_attribute(:author_id) }
          .from(author.id).to(new_author.id)
      end
    end
  end
end
