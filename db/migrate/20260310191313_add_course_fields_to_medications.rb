class AddCourseFieldsToMedications < ActiveRecord::Migration[8.1]
  def change
    add_column :medications, :course, :boolean, null: false, default: false
    add_column :medications, :starts_on, :date
    add_column :medications, :ends_on, :date
    add_index :medications, :ends_on
  end
end
