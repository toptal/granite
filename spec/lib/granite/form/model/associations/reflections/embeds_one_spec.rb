require 'spec_helper'

RSpec.describe Granite::Form::Model::Associations::Reflections::EmbedsOne do
  before do
    stub_model_granite_form(:author) do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations
      attribute :name, String
    end

    stub_model_granite_form(:book) do
      include Granite::Form::Model::Associations

      attribute :title, String
      embeds_one :author
    end
  end

  let(:book) { Book.new }

  specify { expect(book.author).to be_nil }

  context ':read, :write' do
    before do
      stub_model_granite_form(:book) do
        include Granite::Form::Model::Persistence
        include Granite::Form::Model::Associations

        attribute :title
        embeds_one :author,
                   read: lambda { |reflection, object|
                     value = object.instance_variable_get("@_value_#{reflection.name}")
                     JSON.parse(value) if value.present?
                   },
                   write: lambda { |reflection, object, value|
                     value = value.to_json if value
                     object.instance_variable_set("@_value_#{reflection.name}", value)
                   }
      end
    end

    let(:book) { Book.new }
    let(:author) { Author.new(name: 'Rick') }

    specify do
      expect do
        book.author = author
        book.association(:author).sync
      end
        .to change { book.author(true) }
        .from(nil).to(have_attributes(name: 'Rick'))
    end
  end

  describe '#author=' do
    let(:author) { Author.new name: 'Author' }

    specify { expect { book.author = author }.to change { book.author }.from(nil).to(author) }
    specify { expect { book.author = 'string' }.to raise_error Granite::Form::AssociationTypeMismatch }

    context do
      let(:other) { Author.new name: 'Other' }

      before { book.author = other }

      specify { expect { book.author = author }.to change { book.author }.from(other).to(author) }
      specify { expect { book.author = nil }.to change { book.author }.from(other).to(nil) }
    end
  end

  describe '#build_author' do
    let(:author) { Author.new name: 'Author' }

    specify { expect(book.build_author(name: 'Author')).to eq(author) }
    specify { expect { book.build_author(name: 'Author') }.to change { book.author }.from(nil).to(author) }
  end

  context 'on the fly' do
    context do
      before do
        stub_model_granite_form(:book) do
          include Granite::Form::Model::Associations

          attribute :title, String
          embeds_one :author do
            attribute :name, String
          end
        end
      end

      specify { expect(Book.reflect_on_association(:author).klass).to eq(Book::Author) }
      specify { expect(Book.new.author).to be_nil }
      specify { expect(Book.new.tap { |b| b.build_author(name: 'Author') }.author).to be_a(Book::Author) }
      specify { expect(Book.new.tap { |b| b.build_author(name: 'Author') }.author).to have_attributes(name: 'Author') }
    end

    context do
      before do
        stub_model_granite_form(:book) do
          include Granite::Form::Model::Associations

          attribute :title, String
          embeds_one :author, class_name: 'Author' do
            attribute :age, Integer
          end
        end
      end

      specify { expect(Book.reflect_on_association(:author).klass).to eq(Book::Author) }
      specify { expect(Book.new.author).to be_nil }
      specify { expect(Book.new.tap { |b| b.build_author(name: 'Author') }.author).to be_a(Book::Author) }

      specify do
        book = Book.new
        book.build_author(name: 'Author')
        expect(book.author).to have_attributes(name: 'Author', age: nil)
      end
    end
  end
end
