# frozen_string_literal: true

require "test_helper"

class Admin::SiteSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin_user)
    @member = users(:new_user)
  end

  test "admin can toggle registration closed" do
    sign_in_as(@admin)
    assert SiteSetting.registration_open?

    post admin_toggle_registration_path
    assert_redirected_to admin_root_path

    Rails.cache.delete("site_setting:registration_open")
    assert_not SiteSetting.registration_open?
    assert_match "closed", flash[:notice]
  end

  test "admin can toggle registration open" do
    site_settings(:registration_open).update!(value: "false")
    Rails.cache.delete("site_setting:registration_open")

    sign_in_as(@admin)
    post admin_toggle_registration_path
    assert_redirected_to admin_root_path

    Rails.cache.delete("site_setting:registration_open")
    assert SiteSetting.registration_open?
    assert_match "open", flash[:notice]
  end

  test "member cannot toggle registration" do
    sign_in_as(@member)
    post admin_toggle_registration_path
    assert_redirected_to root_path
  end

  test "unauthenticated user cannot toggle registration" do
    post admin_toggle_registration_path
    assert_redirected_to new_session_path
  end
end
