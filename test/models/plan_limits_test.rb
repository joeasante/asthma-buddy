# frozen_string_literal: true

require "test_helper"

class PlanLimitsTest < ActiveSupport::TestCase
  test "history_cutoff_date returns nil for premium users (unlimited)" do
    user = users(:admin_user) # admin is always premium
    assert_nil user.history_cutoff_date(:symptom_log_history_days)
    assert_nil user.history_cutoff_date(:peak_flow_history_days)
  end

  test "history_cutoff_date returns a date 30 days ago for free users" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:symptom_log_history_days)
    assert_not_nil cutoff
    expected = 30.days.ago.beginning_of_day
    assert_in_delta expected.to_f, cutoff.to_f, 1.0, "Cutoff should be ~30 days ago"
  end

  test "history_cutoff_date returns beginning_of_day" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:symptom_log_history_days)
    assert_equal cutoff, cutoff.beginning_of_day, "Cutoff should be beginning of day, not current time"
  end

  test "history_cutoff_date works for peak flow history" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:peak_flow_history_days)
    assert_not_nil cutoff
    expected = 30.days.ago.beginning_of_day
    assert_in_delta expected.to_f, cutoff.to_f, 1.0
  end

  # -- Trial state tests --

  test "on_trial? returns true for trialing subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_test",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 27.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert user.on_trial?, "User with trialing subscription should be on_trial?"
  end

  test "subscription_status returns trialing for trialing subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_status",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 27.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_equal "trialing", user.subscription_status
  end

  test "trial_ends_at returns the trial end date" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    trial_end = 27.days.from_now
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_ends",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: trial_end,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_in_delta trial_end.to_f, user.trial_ends_at.to_f, 1.0
  end

  test "premium? returns true for trialing subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_premium",
      processor_plan: "price_test",
      status: "trialing",
      trial_ends_at: 27.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert user.premium?, "Trialing user should be premium"
  end

  # -- Paused state tests --

  test "paused? returns true for paused subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_paused_test",
      processor_plan: "price_test",
      status: "paused",
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert user.paused?, "User with paused subscription should be paused?"
  end

  test "subscription_status returns paused for paused subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_paused_status",
      processor_plan: "price_test",
      status: "paused",
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_equal "paused", user.subscription_status
  end

  test "premium? returns false for paused subscription" do
    user = users(:verified_user)
    user.set_payment_processor :stripe
    user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_paused_premium",
      processor_plan: "price_test",
      status: "paused",
      type: "Pay::Stripe::Subscription"
    )
    user.payment_processor.reload

    assert_not user.premium?, "Paused user should not be premium"
  end
end
