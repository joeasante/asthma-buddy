# frozen_string_literal: true

require "test_helper"

class TrialReminderJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  test "sends email to users with trials ending in 3 days" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_reminder_3d",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 3.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_enqueued_emails 1 do
      TrialReminderJob.perform_now
    end
  end

  test "does not send to users whose trial has already ended" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_ended",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 1.day.ago,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_enqueued_emails 0 do
      TrialReminderJob.perform_now
    end
  end

  test "does not send to active (non-trialing) subscribers" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_active_no_trial",
      processor_plan: "price_test",
      status: "active",
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_enqueued_emails 0 do
      TrialReminderJob.perform_now
    end
  end

  test "does not send to users with trials ending in 10 days" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_10d",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 10.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_enqueued_emails 0 do
      TrialReminderJob.perform_now
    end
  end
end
