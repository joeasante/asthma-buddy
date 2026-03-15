# frozen_string_literal: true

require "test_helper"

class PlanLimitsTest < ActiveSupport::TestCase
  test "history_cutoff_date returns nil for premium users (unlimited)" do
    user = users(:admin_user) # admin is always premium
    assert_nil user.history_cutoff_date(:symptom_log_history_days)
    assert_nil user.history_cutoff_date(:peak_flow_history_days)
  end

  test "history_cutoff_date returns a date 30 days ago for free users" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:symptom_log_history_days)
    assert_not_nil cutoff
    expected = 30.days.ago.beginning_of_day
    assert_in_delta expected.to_f, cutoff.to_f, 1.0, "Cutoff should be ~30 days ago"
  end

  test "history_cutoff_date returns beginning_of_day" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:symptom_log_history_days)
    assert_equal cutoff, cutoff.beginning_of_day, "Cutoff should be beginning of day, not current time"
  end

  test "history_cutoff_date works for peak flow history" do
    user = users(:verified_user)
    cutoff = user.history_cutoff_date(:peak_flow_history_days)
    assert_not_nil cutoff
    expected = 30.days.ago.beginning_of_day
    assert_in_delta expected.to_f, cutoff.to_f, 1.0
  end
end
