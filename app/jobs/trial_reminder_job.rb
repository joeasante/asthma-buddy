# frozen_string_literal: true

class TrialReminderJob < ApplicationJob
  queue_as :default

  def perform
    reminder_window_start = 3.days.from_now.beginning_of_day
    reminder_window_end = 3.days.from_now.end_of_day

    notified_user_ids = Set.new

    Pay::Subscription.where(status: "trialing")
                     .where(trial_ends_at: reminder_window_start..reminder_window_end)
                     .includes(customer: :owner)
                     .find_each do |subscription|
      user = subscription.customer.owner
      next unless user.is_a?(User)
      next if notified_user_ids.include?(user.id)

      notified_user_ids.add(user.id)
      BillingMailer.trial_ending_soon(user).deliver_later
    end
  end
end
