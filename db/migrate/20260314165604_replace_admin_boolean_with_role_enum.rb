# frozen_string_literal: true

class ReplaceAdminBooleanWithRoleEnum < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :integer, default: 0, null: false

    # Backfill: admin boolean true -> role 1 (admin)
    execute "UPDATE users SET role = 1 WHERE admin = 1"

    remove_column :users, :admin
    add_index :users, :role
  end

  def down
    add_column :users, :admin, :boolean, default: false, null: false

    execute "UPDATE users SET admin = 1 WHERE role = 1"

    remove_index :users, :role
    remove_column :users, :role
  end
end
