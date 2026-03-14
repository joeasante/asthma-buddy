# frozen_string_literal: true

require "application_system_test_case"

class AdminTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin_user)
  end

  test "admin dashboard renders for admin user" do
    sign_in_as @admin
    visit admin_root_url
    assert_selector "h1", text: "Stats"
    assert_selector ".admin-stat-grid"
    assert_selector ".admin-site-setting"
  end

  test "admin users page renders for admin user" do
    sign_in_as @admin
    visit admin_users_url
    assert_selector "h1", text: "Users"
    assert_selector ".admin-table"
  end

  test "non-admin is redirected from admin dashboard" do
    sign_in_as users(:verified_user)
    visit admin_root_url
    assert_no_current_path admin_root_url
  end
end
