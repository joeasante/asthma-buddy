# frozen_string_literal: true

require "test_helper"

class AdherenceControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get adherence_url
    assert_redirected_to new_session_url
  end

  test "index renders successfully for authenticated user" do
    get adherence_url
    assert_response :success
    assert_select "h1", "Preventer Adherence"
  end

  test "index defaults to 7-day range" do
    get adherence_url
    assert_response :success
    # The active toggle button should be 7 days
    assert_select "a.adherence-toggle-btn--active", text: "7 days"
  end

  test "index accepts days=30 param" do
    get adherence_url, params: { days: 30 }
    assert_response :success
    assert_select "a.adherence-toggle-btn--active", text: "30 days"
  end

  test "index ignores invalid days param and defaults to 7" do
    get adherence_url, params: { days: 99 }
    assert_response :success
    assert_select "a.adherence-toggle-btn--active", text: "7 days"
  end

  test "index only shows preventers with doses_per_day (alice_preventer, not alice_reliever or alice_combination)" do
    get adherence_url
    assert_response :success
    # alice_preventer (Clenil Modulite) has doses_per_day: 2 — should appear
    assert_select ".adherence-medication-name", text: "Clenil Modulite"
    # alice_reliever (Ventolin) has no doses_per_day — must NOT appear
    assert_select ".adherence-medication-name", text: "Ventolin", count: 0
    # alice_combination (Fostair) has no doses_per_day — must NOT appear
    assert_select ".adherence-medication-name", text: "Fostair", count: 0
  end

  test "index does not expose another user's medications" do
    get adherence_url
    # bob_reliever belongs to unverified_user — must NOT appear
    assert_select ".adherence-medication-name", text: "Salbutamol", count: 0
  end
end
