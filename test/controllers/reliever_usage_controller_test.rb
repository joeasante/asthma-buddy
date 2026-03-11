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
    # Dynamically look up Bob's reliever medication names so this test
    # stays correct if fixtures are renamed.
    bob_med_names = users(:unverified_user).medications
                      .where(medication_type: :reliever)
                      .pluck(:name)
    assert bob_med_names.any?, "unverified_user must have at least one reliever for this test to be meaningful"

    get reliever_usage_url
    assert_response :success

    bob_med_names.each do |name|
      assert_no_match(/#{Regexp.escape(name)}/i, response.body)
    end
  end

  # ── Empty states ──────────────────────────────────────────────────────────

  test "index renders empty state when user has no reliever medications" do
    @user.medications.where(medication_type: :reliever).destroy_all
    get reliever_usage_url
    assert_response :success
    assert_select "h3", text: "No reliever medications"
    assert_select "a.btn-primary", text: "Add reliever inhaler"
  end

  test "index renders has-relievers-but-no-logs empty state" do
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
    assert_select ".reliever-bars"
    assert_select ".reliever-bar-col"
  end

  test "index renders GINA band modifier classes on bar fills" do
    get reliever_usage_url
    assert_response :success
    # Verify that bar fills are rendered with at least one GINA band modifier class.
    # Specific bands (controlled / review / urgent) depend on which fixtures fall
    # in which calendar week at time of test; we assert structural correctness here.
    assert_select ".reliever-bar-fill"
    assert_select "[class*='reliever-bar-fill--']"
  end

  test "index returns exactly 8 bars for 8-week range" do
    get reliever_usage_url, params: { weeks: 8 }
    assert_response :success
    assert_select ".reliever-bar-col", count: 8
  end

  test "index returns exactly 12 bars for 12-week range" do
    get reliever_usage_url, params: { weeks: 12 }
    assert_response :success
    assert_select ".reliever-bar-col", count: 12
  end

  # ── JSON format ───────────────────────────────────────────────────────────

  test "index responds to JSON format" do
    get reliever_usage_url, as: :json
    assert_response :success
    json = response.parsed_body
    assert json.key?("weekly_data"), "JSON response must include weekly_data"
    assert json.key?("monthly_uses"), "JSON response must include monthly_uses"
    assert json.key?("gina_bands"), "JSON response must include gina_bands"
    assert_equal @user.medications.where(medication_type: :reliever).count > 0,
                 json["weekly_data"].any?,
                 "weekly_data must be non-empty when user has reliever logs"

    # Structural assertions: weekly_data items
    if json["weekly_data"].any?
      item = json["weekly_data"].first
      assert item.key?("week_start"), "weekly_data item must have week_start"
      assert item.key?("week_end"),   "weekly_data item must have week_end"
      assert item.key?("uses"),       "weekly_data item must have uses"
      assert item.key?("band"),       "weekly_data item must have band"
      assert item.key?("label"),      "weekly_data item must have label"
      valid_bands = %w[controlled review urgent]
      assert_includes valid_bands, item["band"], "band must be one of #{valid_bands}"
    end

    # gina_bands structure
    gina = json["gina_bands"]
    assert gina.key?("controlled"), "gina_bands must have controlled key"
    assert gina.key?("review"),     "gina_bands must have review key"
    assert gina.key?("urgent"),     "gina_bands must have urgent key"

    # monthly_window structure
    assert json.key?("monthly_window"), "JSON response must include monthly_window"
    mw = json["monthly_window"]
    assert mw.key?("start"), "monthly_window must have start key"
    assert mw.key?("end"),   "monthly_window must have end key"

    # correlation structure (if present)
    if json["correlation"]
      corr = json["correlation"]
      assert corr.key?("high_use_week_avg_peak_flow"), "correlation must have high_use_week_avg_peak_flow"
      assert corr.key?("low_use_week_avg_peak_flow"),  "correlation must have low_use_week_avg_peak_flow"
      assert corr.key?("threshold_uses"),              "correlation must have threshold_uses"
    end
  end

  test "index JSON unauthenticated returns 401" do
    sign_out
    get reliever_usage_url, as: :json
    assert_response :unauthorized
  end
end
