require 'bundler/setup'

ActiveRecord::Schema.define(version: 2017_11_16_12_20_01) do # rubocop:disable Style/NumericLiterals
  create_table :roles, force: :cascade do |t|
    t.string :status
    t.timestamps
  end

  create_table :users, force: :cascade do |t|
    t.string :email
    t.string :full_name
    t.integer :sign_in_count
    t.integer :related_ids, array: true, default: []
    t.column :projects, :text
    t.column :profile, :text

    t.timestamps
  end

  create_table :authors, force: :cascade do |t|
    t.column :name, :string
    t.column :status, :integer
    t.column :related_ids, :integer, array: true
    t.column :data, :text
  end

  if ActiveModel.version >= Gem::Version.new('7.0.0')
    create_enum 'foo', %w[foo bar baz]

    create_table :foo_containers, force: :cascade do |t|
      t.enum :foos, enum_type: 'foo', array: true
    end
  end
end

if ActiveModel.version >= Gem::Version.new('7.0.0')
  class FooContainer < ActiveRecord::Base
  end
end
