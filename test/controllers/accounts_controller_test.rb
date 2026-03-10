# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "DELETE /account with correct confirmation destroys user and redirects to root" do
    assert_difference "User.count", -1 do
      delete account_path, params: { confirmation: "DELETE" }
    end
    assert_redirected_to root_path
    assert_equal "Your account and all associated data have been permanently deleted.", flash[:notice]
  end

  test "DELETE /account with wrong confirmation does not destroy user" do
    assert_no_difference "User.count" do
      delete account_path, params: { confirmation: "delete" }
    end
    assert_redirected_to settings_path
    assert_equal "Account not deleted. You must type DELETE exactly to confirm.", flash[:alert]
  end

  test "DELETE /account with empty confirmation does not destroy user" do
    assert_no_difference "User.count" do
      delete account_path, params: { confirmation: "" }
    end
    assert_redirected_to settings_path
  end

  test "unauthenticated DELETE /account redirects to sign in" do
    sign_out
    delete account_path, params: { confirmation: "DELETE" }
    assert_redirected_to new_session_path
  end

  test "deleted user cannot sign back in" do
    delete account_path, params: { confirmation: "DELETE" }
    sign_out
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end
end
