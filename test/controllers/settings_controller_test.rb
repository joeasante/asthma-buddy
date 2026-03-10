# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "show renders settings page" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "unauthenticated user is redirected from settings" do
    sign_out
    get settings_path
    assert_redirected_to new_session_path
  end
end
