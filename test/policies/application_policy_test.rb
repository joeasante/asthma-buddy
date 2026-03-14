# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  setup do
    @user = users(:verified_user)
    @record = symptom_logs(:alice_wheezing)
  end

  test "deny-by-default: index? returns false" do
    assert_not ApplicationPolicy.new(@user, @record).index?
  end

  test "deny-by-default: show? returns false" do
    assert_not ApplicationPolicy.new(@user, @record).show?
  end

  test "deny-by-default: create? returns false" do
    assert_not ApplicationPolicy.new(@user, @record).create?
  end

  test "deny-by-default: update? returns false" do
    assert_not ApplicationPolicy.new(@user, @record).update?
  end

  test "deny-by-default: destroy? returns false" do
    assert_not ApplicationPolicy.new(@user, @record).destroy?
  end

  test "deny-by-default: Scope resolves to none" do
    scope = ApplicationPolicy::Scope.new(@user, SymptomLog.all).resolve
    assert_empty scope
  end
end
