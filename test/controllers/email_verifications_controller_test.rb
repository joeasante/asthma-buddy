# frozen_string_literal: true
require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  test "GET /email_verification/:token with valid token sets email_verified_at and redirects" do
    user = users(:unverified_user)
    assert_nil user.email_verified_at

    token = user.generate_token_for(:email_verification)
    get email_verification_path(token)

    assert_redirected_to new_session_path
    assert_equal "Email verified! You can now sign in.", flash[:notice]
    assert_not_nil user.reload.email_verified_at
  end

  test "GET /email_verification/:token with already-verified user redirects with already verified notice" do
    user = users(:verified_user)
    assert_not_nil user.email_verified_at

    token = user.generate_token_for(:email_verification)
    get email_verification_path(token)

    assert_redirected_to new_session_path
    assert_equal "Email already verified.", flash[:notice]
  end

  test "GET /email_verification/:token with invalid token redirects with error alert" do
    get email_verification_path("this-is-not-a-valid-token")

    assert_redirected_to new_session_path
    assert_equal "Invalid or expired verification link.", flash[:alert]
  end

  test "GET /email_verification/:token with expired token redirects with error alert" do
    user = users(:unverified_user)

    # Generate token then travel past expiry (24 hours + 1 minute)
    token = user.generate_token_for(:email_verification)

    travel 25.hours do
      get email_verification_path(token)
    end

    assert_redirected_to new_session_path
    assert_equal "Invalid or expired verification link.", flash[:alert]
  end

  # --- JSON ---

  test "GET /email_verification/:token with valid token returns 200 JSON" do
    user = users(:unverified_user)
    token = user.generate_token_for(:email_verification)

    get email_verification_path(token), as: :json

    assert_response :ok
    assert_equal "Email verified. You can now sign in.", response.parsed_body["message"]
    assert_not_nil user.reload.email_verified_at
  end

  test "GET /email_verification/:token with already-verified user returns 200 JSON" do
    user = users(:verified_user)
    token = user.generate_token_for(:email_verification)

    get email_verification_path(token), as: :json

    assert_response :ok
    assert_equal "Email already verified.", response.parsed_body["message"]
  end

  test "GET /email_verification/:token with invalid token returns 404 JSON" do
    get email_verification_path("bad-token"), as: :json

    assert_response :not_found
    assert_match "invalid or expired", response.parsed_body["error"].downcase
  end
end
