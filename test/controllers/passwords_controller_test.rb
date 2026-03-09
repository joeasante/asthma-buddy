# frozen_string_literal: true
require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:verified_user) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      patch password_path(@user.password_reset_token), params: { password: "newpassword1", password_confirmation: "newpassword1" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      patch password_path(token), params: { password: "nomatch12", password_confirmation: "match1234" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Passwords did not match"
  end

  # --- JSON ---

  test "POST /passwords with existing email returns 200 JSON" do
    post passwords_path, params: { email_address: @user.email_address }, as: :json
    assert_response :ok
    assert_match "reset instructions sent", response.parsed_body["message"]
  end

  test "POST /passwords with unknown email returns 200 JSON (no enumeration)" do
    post passwords_path, params: { email_address: "nobody@example.com" }, as: :json
    assert_response :ok
    assert_match "reset instructions sent", response.parsed_body["message"]
  end

  test "PATCH /passwords/:token with valid token and matching passwords returns 200 JSON" do
    patch password_path(@user.password_reset_token),
      params: { password: "newpassword1", password_confirmation: "newpassword1" },
      as: :json
    assert_response :ok
    assert_equal "Password has been reset.", response.parsed_body["message"]
  end

  test "PATCH /passwords/:token with invalid token returns 404 JSON" do
    patch password_path("bad-token"),
      params: { password: "newpassword1", password_confirmation: "newpassword1" },
      as: :json
    assert_response :not_found
    assert_match "invalid or has expired", response.parsed_body["error"]
  end

  test "PATCH /passwords/:token with mismatched passwords returns 422 JSON" do
    patch password_path(@user.password_reset_token),
      params: { password: "newpassword1", password_confirmation: "different456" },
      as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  private
    def assert_notice(text)
      assert_select "p", /#{text}/
    end
end
