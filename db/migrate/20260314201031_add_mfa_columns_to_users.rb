# frozen_string_literal: true

class AddMfaColumnsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :text
    add_column :users, :otp_required_for_login, :boolean, default: false, null: false
    add_column :users, :otp_recovery_codes, :text
    add_column :users, :last_otp_at, :datetime
  end
end
