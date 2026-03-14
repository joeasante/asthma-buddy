# frozen_string_literal: true

require "test_helper"

class Settings::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
  end

  # -- show --

  test "show renders for authenticated user" do
    sign_in_as @user
    get settings_api_key_path
    assert_response :success
    assert_select "h1", "API Key"
  end

  test "show redirects unauthenticated user to sign-in" do
    get settings_api_key_path
    assert_redirected_to new_session_path
  end

  test "show displays active badge when key exists" do
    @user.generate_api_key!
    sign_in_as @user
    get settings_api_key_path
    assert_select ".badge--enabled", "Active"
  end

  test "show displays none badge when no key exists" do
    sign_in_as @user
    get settings_api_key_path
    assert_select ".badge--disabled", "None"
  end

  # -- create --

  test "create generates a key and renders it inline" do
    sign_in_as @user
    post settings_api_key_path
    assert_response :success
    assert_select "#api-key-value", /\A[0-9a-f]{64}\z/
    assert_equal "API key generated. Copy it now — it won't be shown again.", flash[:notice]
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "create replaces existing key" do
    @user.generate_api_key!
    old_digest = @user.reload.api_key_digest

    sign_in_as @user
    post settings_api_key_path
    assert_response :success

    @user.reload
    assert_not_equal old_digest, @user.api_key_digest
  end

  # -- destroy --

  test "destroy revokes key and redirects" do
    @user.generate_api_key!
    sign_in_as @user

    delete settings_api_key_path
    assert_redirected_to settings_api_key_path
    assert_equal "API key revoked.", flash[:notice]

    @user.reload
    assert_not @user.api_key_active?
  end

  test "destroy when no key exists still succeeds gracefully" do
    sign_in_as @user
    delete settings_api_key_path
    assert_redirected_to settings_api_key_path
    assert_equal "API key revoked.", flash[:notice]
  end
end
