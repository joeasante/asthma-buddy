# frozen_string_literal: true

require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    ActionMailer::Base.deliveries.clear
    # System tests run the app in a thread — use inline adapter so deliver_later
    # executes synchronously and emails land in ActionMailer::Base.deliveries.
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  test "complete auth journey: signup, verify email, login, logout, password reset, login with new password" do
    email = "newuser_#{SecureRandom.hex(4)}@example.com"
    original_password = "testpassword1"
    new_password = "newpassword2"

    # Step 1: Sign up (queue adapter set to :inline in setup — deliver_later executes synchronously)
    visit new_registration_path
    fill_in "Email address", with: email
    fill_in "Password", with: original_password
    fill_in "Confirm password", with: original_password
    click_button "Sign up"

    assert_text "Account created"
    assert_current_path new_session_path

    # Step 2: Extract verification token from email
    assert_equal 1, ActionMailer::Base.deliveries.size, "Expected 1 email after signup"
    verification_email = ActionMailer::Base.deliveries.last
    email_body = verification_email.body.parts.find { |p| p.content_type.include?("text/plain") }&.body&.to_s ||
                 verification_email.body.to_s
    token_match = email_body.match(%r{/email_verification/([A-Za-z0-9+/=_\-]+)})
    assert_not_nil token_match, "Verification token URL not found in email body:\n#{email_body}"
    verification_token = token_match[1]

    # Step 3: Visit verification URL
    visit email_verification_path(verification_token)
    assert_text "Email verified"
    assert_current_path new_session_path

    # Step 4: Log in with original password
    fill_in "Email address", with: email
    fill_in "Password", with: original_password
    click_button "Sign in"

    assert_current_path root_path
    assert_text email
    assert_text "Sign out"

    # Step 5: Navigate away and confirm still logged in
    visit root_path
    assert_text "Sign out"
    assert_text email

    # Step 6: Sign out
    click_on "Sign out"
    assert_text "Sign in"
    assert_text "Sign up"

    # Step 7: Visit login page and go to forgot password
    visit new_session_path
    click_on "Forgot password?"

    assert_current_path new_password_path

    # Step 8: Request password reset
    ActionMailer::Base.deliveries.clear
    fill_in "Email address", with: email
    click_on "Send reset link"

    assert_current_path new_session_path
    assert_text "reset instructions sent"

    # Step 9: Extract reset token from password reset email
    assert_equal 1, ActionMailer::Base.deliveries.size, "Expected 1 email after reset request"
    reset_email = ActionMailer::Base.deliveries.last
    reset_body = reset_email.body.parts.find { |p| p.content_type.include?("text/plain") }&.body&.to_s ||
                 reset_email.body.to_s
    reset_token_match = reset_body.match(%r{/passwords/([A-Za-z0-9+/=_\-]+)/edit})
    assert_not_nil reset_token_match, "Password reset token URL not found in email body:\n#{reset_body}"
    reset_token = reset_token_match[1]

    # Step 10: Visit reset URL and set new password
    visit edit_password_path(reset_token)
    fill_in "New password", with: new_password
    fill_in "Confirm new password", with: new_password
    click_on "Reset password"

    assert_current_path new_session_path
    assert_text "Password has been reset"

    # Step 11: Log in with new password
    fill_in "Email address", with: email
    fill_in "Password", with: new_password
    click_button "Sign in"

    assert_current_path root_path
    assert_text "Sign out"
    assert_text email
  end

  test "nav shows Sign in and Sign up when logged out" do
    visit root_path
    assert_text "Sign in"
    assert_text "Sign up"
    assert_no_text "Sign out"
  end

  test "nav shows email and Sign out when logged in" do
    user = users(:verified_user)
    # Log in via the form
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"

    assert_text user.email_address
    assert_text "Sign out"
    assert_no_text "Sign in"
  end
end
