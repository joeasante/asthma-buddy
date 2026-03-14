# frozen_string_literal: true

require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin      = users(:admin_user)
    @non_admin  = users(:new_user)
  end

  test "GET /admin returns 200 for admin" do
    sign_in_as(@admin)
    get admin_root_path
    assert_response :success
  end

  test "GET /admin redirects non-admin to root" do
    sign_in_as(@non_admin)
    get admin_root_path
    assert_redirected_to root_path
  end

  test "GET /admin redirects unauthenticated to login" do
    get admin_root_path
    assert_redirected_to new_session_path
  end

  test "GET /admin renders stat cards and tables" do
    sign_in_as(@admin)
    get admin_root_path
    assert_response :success

    # Stat card labels appear in response body
    assert_select "p.admin-stat-label", text: "Total Users"
    assert_select "p.admin-stat-label", text: "WAU (7 days)"
    assert_select "p.admin-stat-label", text: "MAU (30 days)"
    assert_select "p.admin-stat-label", text: "Never Returned"
    assert_select "p.admin-stat-label", text: "New This Week"
    assert_select "p.admin-stat-label", text: "New This Month"

    # Both table headings are present
    assert_select "h2.section-card-title", text: "Recent Signups"
    assert_select "h2.section-card-title", text: "Most Active"

    # Fixture users appear in one of the tables
    assert_select "td", text: users(:verified_user).email_address
  end
end
