# frozen_string_literal: true

class FixNullAndDefaultConstraints < ActiveRecord::Migration[8.1]
  def up
    # Backfill any NULL dose_unit values before adding NOT NULL constraint
    execute "UPDATE medications SET dose_unit = 'puffs' WHERE dose_unit IS NULL"
    change_column_null :medications, :dose_unit, false
    change_column_default :medications, :dose_unit, "puffs"

    # Backfill any NULL admin values before adding NOT NULL constraint
    execute "UPDATE users SET admin = 0 WHERE admin IS NULL"
    change_column_null :users, :admin, false
    change_column_default :users, :admin, false
  end

  def down
    change_column_null :medications, :dose_unit, true
    change_column_default :medications, :dose_unit, nil

    change_column_null :users, :admin, true
    change_column_default :users, :admin, nil
  end
end
