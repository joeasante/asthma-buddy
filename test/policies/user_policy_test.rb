# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin_user)
    @member = users(:verified_user)
    @other_member = users(:new_user)
  end

  # -- index? --

  test "index? allows admin" do
    assert UserPolicy.new(@admin, User).index?
  end

  test "index? denies member" do
    assert_not UserPolicy.new(@member, User).index?
  end

  # -- toggle_admin? --

  test "toggle_admin? allows admin for another user" do
    assert UserPolicy.new(@admin, @member).toggle_admin?
  end

  test "toggle_admin? denies admin for self" do
    assert_not UserPolicy.new(@admin, @admin).toggle_admin?
  end

  test "toggle_admin? denies member" do
    assert_not UserPolicy.new(@member, @other_member).toggle_admin?
  end

  test "toggle_admin? denies demoting last admin" do
    # Ensure only one admin exists
    assert_equal 1, User.admin.count
    assert_not UserPolicy.new(@admin, @admin).toggle_admin?
  end

  # -- Scope --

  test "Scope: admin sees all users" do
    scope = UserPolicy::Scope.new(@admin, User.all).resolve
    assert_equal User.count, scope.count
  end

  test "Scope: member sees none" do
    scope = UserPolicy::Scope.new(@member, User.all).resolve
    assert_empty scope
  end
end
