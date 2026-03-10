class AddOnboardingFlagsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :onboarding_personal_best_done, :boolean, default: false, null: false
    add_column :users, :onboarding_medication_done,    :boolean, default: false, null: false
  end
end
