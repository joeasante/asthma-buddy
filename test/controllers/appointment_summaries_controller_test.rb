# frozen_string_literal: true

require "test_helper"

class AppointmentSummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "GET /appointment-summary returns 200 for authenticated user" do
    get appointment_summary_path
    assert_response :success
  end

  test "GET /appointment-summary redirects unauthenticated user" do
    delete session_path
    get appointment_summary_path
    assert_redirected_to new_session_path
  end

  test "GET /appointment-summary renders all five sections" do
    get appointment_summary_path
    assert_response :success
    assert_match "Peak Flow", response.body
    assert_match "Symptoms", response.body
    assert_match "Reliever Use", response.body
    assert_match "Medications", response.body
    assert_match "Health Events", response.body
  end

  test "GET /appointment-summary renders print button" do
    get appointment_summary_path
    assert_match "window.print()", response.body
  end

  test "GET /appointment-summary shows correct period date range" do
    get appointment_summary_path
    assert_match 30.days.ago.to_date.strftime("%-d %b"), response.body
  end

  test "GET /appointment-summary does not show other user data" do
    other_user = users(:unverified_user)
    # Bob's medication name should not appear in Alice's summary
    get appointment_summary_path
    assert_response :success
    assert_no_match "Salbutamol", response.body  # bob_reliever fixture name
  end

  test "GET /appointment-summary shows empty states when no data in period" do
    # Destroy any readings/symptoms in the last 30 days for the verified user
    @user.peak_flow_readings.where(recorded_at: 30.days.ago..).destroy_all
    @user.symptom_logs.where(recorded_at: 30.days.ago..).destroy_all
    get appointment_summary_path
    assert_response :success
    assert_match "No peak flow readings in this period", response.body
    assert_match "No symptoms logged in this period", response.body
  end
end
