# frozen_string_literal: true

require "test_helper"

class RelieverUsageControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  # ── Auth ──────────────────────────────────────────────────────────────────

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get reliever_usage_url
    assert_redirected_to new_session_url
  end

  # ── Basic rendering ───────────────────────────────────────────────────────

  test "index renders successfully for authenticated user" do
    get reliever_usage_url
    assert_response :success
    assert_select "h1", "Reliever Usage"
  end

  # ── Period param ──────────────────────────────────────────────────────────

  test "index defaults to 8-week range" do
    get reliever_usage_url
    assert_response :success
    assert_select "a.btn-sm--active", text: "8 weeks"
  end

  test "index accepts weeks=12 param" do
    get reliever_usage_url, params: { weeks: 12 }
    assert_response :success
    assert_select "a.btn-sm--active", text: "12 weeks"
  end

  test "index ignores invalid weeks param and defaults to 8" do
    get reliever_usage_url, params: { weeks: 99 }
    assert_response :success
    assert_select "a.btn-sm--active", text: "8 weeks"
  end

  # ── Cross-user isolation ──────────────────────────────────────────────────

  test "index does not expose another user's reliever dose logs" do
    get reliever_usage_url
    assert_response :success
    # Bob's Salbutamol must never appear in Alice's view.
    # The page should not contain "Salbutamol" anywhere in the body.
    assert_no_match(/Salbutamol/i, response.body)
  end

  # ── Empty states ──────────────────────────────────────────────────────────

  test "index renders empty state when user has no reliever medications" do
    # Sign in as a user who has no medications at all.
    # Use unverified_user's bob account but we need a user with zero relievers.
    # Create a user inline via a temporary approach: sign in as verified_user
    # and temporarily destroy their reliever medication.
    @user.medications.where(medication_type: :reliever).destroy_all
    # Also destroy alice_reliever dose logs so there are none.
    get reliever_usage_url
    assert_response :success
    assert_select "h3", text: "No reliever medications"
    assert_select "a.btn-primary", text: "Add reliever inhaler"
  end

  test "index renders has-relievers-but-no-logs empty state" do
    # Destroy all of Alice's reliever dose logs, keeping her alice_reliever medication.
    @user.dose_logs.joins(:medication).where(medications: { medication_type: :reliever }).destroy_all
    get reliever_usage_url
    assert_response :success
    assert_select "h3", text: "No doses logged yet"
    assert_select "a.btn-secondary", text: "Go to Medications"
  end

  # ── Data correctness ─────────────────────────────────────────────────────

  test "index shows bar chart when reliever logs exist" do
    get reliever_usage_url
    assert_response :success
    # The bar chart container must be present.
    assert_select ".reliever-bars"
    # At least one bar column should be rendered.
    assert_select ".reliever-bar-col"
  end

  test "index renders GINA band classes on bar fills" do
    get reliever_usage_url
    assert_response :success
    # We have fixtures with 4 uses in one week (review band) and 7 in another (urgent band).
    # At least the controlled band (alice_reliever_dose_1 + _2 = 2 uses this week) must appear.
    # The view must include at least one reliever-bar-fill element.
    assert_select ".reliever-bar-fill"
    # Bars must carry one of the three GINA band modifier classes.
    assert_select "[class*='reliever-bar-fill--']"
  end
end
