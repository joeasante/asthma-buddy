class AddActivityTrackingToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :sign_in_count, :integer, null: false, default: 0
  end
end
