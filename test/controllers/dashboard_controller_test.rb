# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "GET /dashboard returns 200 for authenticated user" do
    get dashboard_path
    assert_response :success
  end

  test "GET /dashboard renders status card" do
    get dashboard_path
    assert_select ".dash-status"
  end

  test "GET /dashboard renders summary stats" do
    get dashboard_path
    assert_select ".dash-stats"
    assert_select ".dash-stat", minimum: 3
  end

  test "GET /dashboard renders quick log buttons" do
    get dashboard_path
    assert_select ".dash-quick-log"
    assert_select ".dash-quick-btn", minimum: 2
  end

  test "GET /dashboard renders recent entries section" do
    get dashboard_path
    assert_select ".dash-recents"
  end

  test "GET / redirects authenticated user to dashboard" do
    get root_url
    assert_redirected_to dashboard_path
  end

  test "GET /dashboard redirects unauthenticated user to sign in" do
    delete session_path
    get dashboard_path
    assert_redirected_to new_session_path
  end
end
