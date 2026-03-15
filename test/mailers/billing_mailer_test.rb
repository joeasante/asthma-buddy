# frozen_string_literal: true

require "test_helper"

class BillingMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:verified_user)
    @user.set_payment_processor :stripe
    @user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_trial_mailer",
      processor_plan: "price_monthly_test",
      status: "trialing",
      trial_ends_at: 3.days.from_now,
      type: "Pay::Stripe::Subscription"
    )
    @user.payment_processor.reload
  end

  test "trial_ending_soon generates email with correct subject" do
    email = BillingMailer.trial_ending_soon(@user)
    assert_equal "Your Asthma Buddy trial ends in 3 days", email.subject
  end

  test "trial_ending_soon sends to correct user" do
    email = BillingMailer.trial_ending_soon(@user)
    assert_equal [ @user.email_address ], email.to
  end

  test "trial_ending_soon email body contains trial end date" do
    email = BillingMailer.trial_ending_soon(@user)
    assert_match @user.trial_ends_at.strftime("%B %-d, %Y"), email.html_part.body.to_s
    assert_match @user.trial_ends_at.strftime("%B %-d, %Y"), email.text_part.body.to_s
  end

  test "trial_ending_soon email body contains pricing information" do
    email = BillingMailer.trial_ending_soon(@user)
    assert_match PLANS[:premium][:pricing][:monthly][:display], email.html_part.body.to_s
  end

  test "trial_ending_soon email body contains cancellation instructions" do
    email = BillingMailer.trial_ending_soon(@user)
    assert_match "cancel", email.html_part.body.to_s.downcase
    assert_match "billing settings", email.html_part.body.to_s.downcase
  end
end
