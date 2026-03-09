# frozen_string_literal: true

class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :full_name, :string
    add_column :users, :date_of_birth, :date
  end
end
