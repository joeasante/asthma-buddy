# frozen_string_literal: true

class AddIndexesToUsersForAdminQueries < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :created_at
    add_index :users, :last_sign_in_at
  end
end
