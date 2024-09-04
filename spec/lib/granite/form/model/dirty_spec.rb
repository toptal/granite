require 'spec_helper'

RSpec.describe Granite::Form::Model::Dirty do
  before do
    stub_class(:author, ActiveRecord::Base) {}
    stub_model :premodel do
      include Granite::Form::Model::Persistence
      include Granite::Form::Model::Associations

      attribute :age, Integer, default: 33
      alias_attribute :a, :age
    end
    stub_model :model, Premodel do
      include Granite::Form::Model::Dirty

      references_one :author
      references_many :authors
      embeds_one :something do
        attribute :value, String
      end
      attribute :name, String
      alias_attribute :n, :name
      collection :numbers, Integer
    end
  end

  let(:author) { Author.create!(name: 'Name') }
  let(:other_author) { Author.create!(name: 'Other') }

  specify { expect(Model.new.changes).to eq({}) }
  specify { expect(Model.new.tap { |m| m.build_something(value: 'Value') }.changes).to eq({}) }

  specify { expect(Model.new(author: author).changes).to eq('author_id' => [nil, author.id]) }
  specify { expect(Model.new(author_id: author.id).changes).to eq('author_id' => [nil, author.id]) }
  specify { expect(Model.new(authors: [author]).changes).to eq('author_ids' => [[], [author.id]]) }
  specify { expect(Model.new(author_ids: [author.id]).changes).to eq('author_ids' => [[], [author.id]]) }

  specify do
    expect(Model.new(author: author, name: 'Name2').changes)
      .to eq('author_id' => [nil, author.id], 'name' => [nil, 'Name2'])
  end

  specify do
    expect(Model.instantiate(author_id: other_author.id)
    .tap { |m| m.update(author_id: author.id) }.changes)
      .to eq('author_id' => [other_author.id, author.id])
  end

  specify do
    expect(Model.instantiate(author_id: other_author.id)
    .tap { |m| m.update(author: author) }.changes)
      .to eq('author_id' => [other_author.id, author.id])
  end

  specify do
    expect(Model.instantiate(author_ids: [other_author.id])
    .tap { |m| m.update(author_ids: [author.id]) }.changes)
      .to eq('author_ids' => [[other_author.id], [author.id]])
  end

  specify do
    expect(Model.instantiate(author_ids: [other_author.id])
    .tap { |m| m.update(authors: [author]) }.changes)
      .to eq('author_ids' => [[other_author.id], [author.id]])
  end

  specify { expect(Model.new(a: 'blabla').changes).to eq('age' => [33, nil]) }
  specify { expect(Model.new(a: '42').changes).to eq('age' => [33, 42]) }
  specify { expect(Model.instantiate(age: '42').changes).to eq({}) }
  specify { expect(Model.instantiate(age: '42').tap { |m| m.update(a: '43') }.changes).to eq('age' => [42, 43]) }
  specify { expect(Model.new(a: '42').tap { |m| m.update(a: '43') }.changes).to eq('age' => [33, 43]) }
  specify { expect(Model.new(numbers: '42').changes).to eq('numbers' => [[], [42]]) }

  specify { expect(Model.new).not_to respond_to :something_changed? }
  specify { expect(Model.new).to respond_to :n_changed? }

  specify { expect(Model.new(a: '42')).to be_age_changed }
  specify { expect(Model.new(a: '42')).to be_a_changed }
  specify { expect(Model.new(a: '42').age_change).to eq([33, 42]) }
  specify { expect(Model.new(a: '42').a_change).to eq([33, 42]) }
end
