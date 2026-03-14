# frozen_string_literal: true

require "test_helper"

class MfaChallengeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mfa_user = users(:mfa_user)
    @otp_secret = ROTP::Base32.random
    @mfa_user.enable_mfa!(@otp_secret)
  end

  # -- Helpers --

  def enter_pending_mfa_state(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
    assert_redirected_to new_mfa_challenge_path
  end

  def generate_valid_totp_code
    ROTP::TOTP.new(@otp_secret, issuer: "Asthma Buddy").now
  end

  # -- Tests --

  test "GET /mfa-challenge without pending state redirects to login" do
    get new_mfa_challenge_path
    assert_redirected_to new_session_path
  end

  test "GET /mfa-challenge with pending state renders form" do
    enter_pending_mfa_state(@mfa_user)
    get new_mfa_challenge_path
    assert_response :success
    assert_select "input[name=otp_code]"
  end

  test "POST /mfa-challenge with valid TOTP code authenticates user" do
    enter_pending_mfa_state(@mfa_user)
    code = generate_valid_totp_code

    assert_difference "Session.count", 1 do
      post mfa_challenge_path, params: { otp_code: code }
    end
    assert_response :redirect
    assert_nil session[:pending_mfa_user_id]
  end

  test "POST /mfa-challenge with invalid TOTP code re-renders form" do
    enter_pending_mfa_state(@mfa_user)

    post mfa_challenge_path, params: { otp_code: "000000" }
    assert_response :unprocessable_entity
    assert_select "input[name=otp_code]"
  end

  test "POST /mfa-challenge with valid recovery code authenticates user" do
    enter_pending_mfa_state(@mfa_user)
    recovery_code = @mfa_user.recovery_codes.first
    initial_count = @mfa_user.recovery_codes_remaining

    assert_difference "Session.count", 1 do
      post mfa_challenge_path, params: { otp_code: recovery_code }
    end
    assert_response :redirect
    follow_redirect!
    assert_match "Recovery code used", flash[:notice]
    assert_equal initial_count - 1, @mfa_user.reload.recovery_codes_remaining
  end

  test "POST /mfa-challenge with already-used recovery code fails" do
    recovery_code = @mfa_user.recovery_codes.first

    # Use recovery code first time
    enter_pending_mfa_state(@mfa_user)
    post mfa_challenge_path, params: { otp_code: recovery_code }
    assert_response :redirect

    # Sign out
    sign_out

    # Try the same code again
    enter_pending_mfa_state(@mfa_user)
    post mfa_challenge_path, params: { otp_code: recovery_code }
    assert_response :unprocessable_entity
  end

  test "POST /mfa-challenge with expired pending state redirects to login" do
    enter_pending_mfa_state(@mfa_user)

    # Generate a valid code BEFORE time travel (TOTP is time-based)
    code = generate_valid_totp_code

    # Travel past the 5-minute expiry window
    travel 6.minutes do
      post mfa_challenge_path, params: { otp_code: code }
      assert_redirected_to new_session_path
      assert_match "expired", flash[:alert]
    end
  end

  test "POST /mfa-challenge without pending state redirects to login" do
    post mfa_challenge_path, params: { otp_code: "123456" }
    assert_redirected_to new_session_path
  end
end
