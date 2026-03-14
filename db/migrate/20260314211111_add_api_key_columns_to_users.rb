class AddApiKeyColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :api_key_digest, :string
    add_column :users, :api_key_created_at, :datetime
    add_index :users, :api_key_digest, unique: true
  end
end
