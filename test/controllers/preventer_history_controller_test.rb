# frozen_string_literal: true

require "test_helper"

class PreventerHistoryControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get preventer_history_url
    assert_redirected_to new_session_url
  end

  test "index renders successfully for authenticated user" do
    get preventer_history_url
    assert_response :success
    assert_select "h1", "Preventer History"
  end

  test "index defaults to 7-day range" do
    get preventer_history_url
    assert_response :success
    assert_select "a.btn-sm--active", text: "7 days"
  end

  test "index accepts period=30 param" do
    get preventer_history_url, params: { period: 30 }
    assert_response :success
    assert_select "a.btn-sm--active", text: "30 days"
  end

  test "index ignores invalid period param and defaults to 7" do
    get preventer_history_url, params: { period: 99 }
    assert_response :success
    assert_select "a.btn-sm--active", text: "7 days"
  end

  test "index only shows preventers with doses_per_day (alice_preventer, not alice_reliever or alice_combination)" do
    get preventer_history_url
    assert_response :success
    # alice_preventer (Clenil Modulite) has doses_per_day: 2 — should appear
    assert_select ".adherence-medication-name", text: "Clenil Modulite"
    # alice_reliever (Ventolin) has no doses_per_day — must NOT appear
    assert_select ".adherence-medication-name", text: "Ventolin", count: 0
    # alice_combination (Fostair) has no doses_per_day — must NOT appear
    assert_select ".adherence-medication-name", text: "Fostair", count: 0
  end

  test "index does not expose another user's medications" do
    get preventer_history_url
    # bob_reliever belongs to unverified_user — must NOT appear
    assert_select ".adherence-medication-name", text: "Salbutamol", count: 0
  end

  test "index returns JSON with adherence history" do
    get preventer_history_url, headers: { "Accept" => "application/json" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 7, body["period"]
    assert body.key?("days_taken")
    assert body.key?("days_elapsed")
    assert_kind_of Array, body["adherence_history"]

    # alice_preventer (Clenil Modulite, doses_per_day: 2) should appear
    entry = body["adherence_history"].find { |e| e["medication_name"] == "Clenil Modulite" }
    assert_not_nil entry
    assert_equal 2, entry["doses_per_day"]
    assert_kind_of Array, entry["days_data"]
    assert_equal 7, entry["days_data"].length

    day = entry["days_data"].first
    assert day.key?("date")
    assert day.key?("taken")
    assert day.key?("scheduled")
    assert day.key?("status")
  end

  test "index JSON response respects period param" do
    get preventer_history_url, params: { period: 30 }, headers: { "Accept" => "application/json" }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 30, body["period"]

    entry = body["adherence_history"].find { |e| e["medication_name"] == "Clenil Modulite" }
    assert_not_nil entry
    assert_equal 30, entry["days_data"].length
  end

  test "index JSON does not expose another user's medications" do
    get preventer_history_url, headers: { "Accept" => "application/json" }
    assert_response :success

    body = JSON.parse(response.body)
    names = body["adherence_history"].map { |e| e["medication_name"] }
    assert_not_includes names, "Salbutamol"
  end

  test "index JSON returns 401 for unauthenticated user" do
    sign_out
    get preventer_history_url, headers: { "Accept" => "application/json" }
    assert_response :unauthorized
  end
end
