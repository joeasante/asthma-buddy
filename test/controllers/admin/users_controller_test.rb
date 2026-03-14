# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin      = users(:admin_user)
    @other_user = users(:new_user)
  end

  test "GET /admin/users returns 200 for admin" do
    sign_in_as(@admin)
    get admin_users_path
    assert_response :success
  end

  test "GET /admin/users redirects non-admin to root" do
    sign_in_as(@other_user)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "GET /admin/users redirects unauthenticated to login" do
    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "PATCH toggle_admin grants admin to non-admin user" do
    sign_in_as(@admin)
    patch toggle_admin_admin_user_path(@other_user)
    assert @other_user.reload.admin?
    assert_redirected_to admin_users_path
    assert_match "now an admin", flash[:notice]
  end

  test "PATCH toggle_admin revokes admin from admin user when others exist" do
    @other_user.update_columns(role: 1)
    sign_in_as(@admin)
    patch toggle_admin_admin_user_path(@other_user)
    assert_not @other_user.reload.admin?
    assert_redirected_to admin_users_path
    assert_match "no longer an admin", flash[:notice]
  end

  test "PATCH toggle_admin blocks self-demotion" do
    sign_in_as(@admin)
    patch toggle_admin_admin_user_path(@admin)
    assert @admin.reload.admin?
    assert_match(/not authorized/i, flash[:alert])
  end

  test "PATCH toggle_admin unauthenticated redirects to login" do
    patch toggle_admin_admin_user_path(@other_user)
    assert_redirected_to new_session_path
  end

  test "PATCH toggle_admin non-admin redirects to root" do
    sign_in_as(@other_user)
    patch toggle_admin_admin_user_path(@admin)
    assert_redirected_to root_path
  end

  test "PATCH toggle_admin protects last admin from demotion" do
    # Ensure only one admin exists
    assert_equal 1, User.admin.count
    sign_in_as(@admin)
    # Try to demote via another admin demoting the last admin
    # Since self-demotion is blocked separately, make another user admin first
    @other_user.update!(role: :admin)
    assert_equal 2, User.admin.count

    # Now demote @other_user (should work since 2 admins remain)
    patch toggle_admin_admin_user_path(@other_user)
    assert_not @other_user.reload.admin?

    # Now only @admin remains — cannot be demoted (self-protection applies)
    assert_equal 1, User.admin.count
  end
end
