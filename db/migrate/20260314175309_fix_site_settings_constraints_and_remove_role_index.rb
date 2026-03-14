# frozen_string_literal: true

class FixSiteSettingsConstraintsAndRemoveRoleIndex < ActiveRecord::Migration[8.1]
  def change
    change_column_null :site_settings, :key, false

    unless index_exists?(:site_settings, :key, unique: true)
      add_index :site_settings, :key, unique: true
    end

    if index_exists?(:users, :role)
      remove_index :users, :role
    end
  end
end
