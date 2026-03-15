class AddStatusTrialEndsAtIndexToPaySubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_index :pay_subscriptions, [ :status, :trial_ends_at ], name: "index_pay_subscriptions_on_status_and_trial_ends_at"
  end
end
