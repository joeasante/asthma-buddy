class AddRefilledAtToMedications < ActiveRecord::Migration[8.1]
  def change
    add_column :medications, :refilled_at, :datetime
  end
end
