# frozen_string_literal: true

require "test_helper"

# SettingsController now permanently redirects to ProfilesController.
# These tests verify the redirect behaviour is correct.
class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "show redirects to profile" do
    get settings_path
    assert_redirected_to profile_path
  end

  test "unauthenticated user is redirected from settings" do
    delete session_path
    get settings_path
    assert_redirected_to new_session_path
  end
end
