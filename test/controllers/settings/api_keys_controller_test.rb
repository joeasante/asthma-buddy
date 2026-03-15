# frozen_string_literal: true

require "test_helper"

class Settings::ApiKeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @admin = users(:admin_user)
  end

  # -- show --

  test "show renders for authenticated free user with upgrade prompt" do
    sign_in_as @user
    get settings_api_key_path
    assert_response :success
    assert_select "h1", "API Key"
    assert_select ".badge--disabled", "Premium Feature"
    assert_select "a[href='#{settings_billing_path}']", "Upgrade to Premium"
  end

  test "show renders for premium user with key management UI" do
    sign_in_as @admin
    get settings_api_key_path
    assert_response :success
    assert_select "h1", "API Key"
    assert_select ".badge--disabled", "None"
  end

  test "show redirects unauthenticated user to sign-in" do
    get settings_api_key_path
    assert_redirected_to new_session_path
  end

  test "show displays active badge when premium user has key" do
    @admin.generate_api_key!
    sign_in_as @admin
    get settings_api_key_path
    assert_select ".badge--enabled", "Active"
  end

  # -- create --

  test "create is denied for free users" do
    sign_in_as @user
    post settings_api_key_path
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "create generates a key for premium user" do
    sign_in_as @admin
    post settings_api_key_path
    assert_response :success
    assert_select "#api-key-value", /\A[0-9a-f]{64}\z/
    assert_equal "API key generated. Copy it now — it won't be shown again.", flash[:notice]
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "create replaces existing key for premium user" do
    @admin.generate_api_key!
    old_digest = @admin.reload.api_key_digest

    sign_in_as @admin
    post settings_api_key_path
    assert_response :success

    @admin.reload
    assert_not_equal old_digest, @admin.api_key_digest
  end

  # -- destroy --

  test "destroy is denied for free users" do
    sign_in_as @user
    delete settings_api_key_path
    assert_response :redirect
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "destroy revokes key for premium user" do
    @admin.generate_api_key!
    sign_in_as @admin

    delete settings_api_key_path
    assert_redirected_to settings_api_key_path
    assert_equal "API key revoked.", flash[:notice]

    @admin.reload
    assert_not @admin.api_key_active?
  end

  test "destroy when no key exists still succeeds for premium user" do
    sign_in_as @admin
    delete settings_api_key_path
    assert_redirected_to settings_api_key_path
    assert_equal "API key revoked.", flash[:notice]
  end
end
