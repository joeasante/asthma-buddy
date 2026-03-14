# frozen_string_literal: true

require "test_helper"

class SymptomLogPolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:verified_user)
    @other_user = users(:new_user)
    @log = symptom_logs(:alice_wheezing)
  end

  # -- show? --

  test "show? allows owner" do
    assert SymptomLogPolicy.new(@owner, @log).show?
  end

  test "show? denies non-owner" do
    assert_not SymptomLogPolicy.new(@other_user, @log).show?
  end

  # -- create? --

  test "create? allows any authenticated user" do
    assert SymptomLogPolicy.new(@owner, SymptomLog.new).create?
    assert SymptomLogPolicy.new(@other_user, SymptomLog.new).create?
  end

  # -- update? --

  test "update? allows owner" do
    assert SymptomLogPolicy.new(@owner, @log).update?
  end

  test "update? denies non-owner" do
    assert_not SymptomLogPolicy.new(@other_user, @log).update?
  end

  # -- destroy? --

  test "destroy? allows owner" do
    assert SymptomLogPolicy.new(@owner, @log).destroy?
  end

  test "destroy? denies non-owner" do
    assert_not SymptomLogPolicy.new(@other_user, @log).destroy?
  end

  # -- Scope --

  test "Scope returns only user's own records" do
    scope = SymptomLogPolicy::Scope.new(@owner, SymptomLog.all).resolve
    scope.each do |log|
      assert_equal @owner, log.user
    end
    assert scope.count > 0, "Owner should have symptom logs"
  end

  test "Scope does not include other user's records" do
    scope = SymptomLogPolicy::Scope.new(@owner, SymptomLog.all).resolve
    bob_log = symptom_logs(:bob_coughing)
    assert_not_includes scope.to_a, bob_log
  end
end
