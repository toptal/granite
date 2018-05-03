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
    t.timestamps
  end
end
