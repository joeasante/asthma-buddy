class AllowNullInhalerFieldsOnCourses < ActiveRecord::Migration[8.1]
  def change
    change_column_null :medications, :standard_dose_puffs, true
    change_column_null :medications, :starting_dose_count, true
  end
end
