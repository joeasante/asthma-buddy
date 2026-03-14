# frozen_string_literal: true

require "test_helper"

class AppointmentSummariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "GET /health-report returns 200 for authenticated user" do
    get health_report_path
    assert_response :success
  end

  test "GET /health-report redirects unauthenticated user" do
    delete session_path
    get health_report_path
    assert_redirected_to new_session_path
  end

  test "GET /health-report renders all five sections" do
    get health_report_path
    assert_response :success
    assert_match "Peak Flow", response.body
    assert_match "Symptoms", response.body
    assert_match "Reliever Use", response.body
    assert_match "Medications", response.body
    assert_match "Health Events", response.body
  end

  test "GET /health-report renders print button" do
    get health_report_path
    assert_match 'data-action="click->print#print"', response.body
  end

  test "GET /health-report shows correct period date range" do
    get health_report_path
    assert_match 30.days.ago.to_date.strftime("%-d %b"), response.body
  end

  test "GET /health-report does not show other user data" do
    other_user = users(:unverified_user)
    # Bob's medication name should not appear in Alice's summary
    get health_report_path
    assert_response :success
    assert_no_match "Salbutamol", response.body  # bob_reliever fixture name
  end

  test "GET /health-report renders individual peak flow readings table" do
    reading = @user.peak_flow_readings.create!(
      value: 420, time_of_day: :morning,
      recorded_at: 5.days.ago.change(hour: 8)
    )
    get health_report_path
    assert_response :success
    assert_match "Individual Readings", response.body
    assert_match "420", response.body
    assert_match "08:00", response.body
    reading.destroy
  end

  test "GET /health-report renders individual symptom records" do
    log = @user.symptom_logs.create!(
      symptom_type: :wheezing, severity: :moderate,
      recorded_at: 3.days.ago
    )
    get health_report_path
    assert_response :success
    assert_match "Individual Records", response.body
    assert_match "Wheezing", response.body
    log.destroy
  end

  test "GET /health-report renders dose log details" do
    reliever = @user.medications.find_by(medication_type: :reliever, course: false)
    skip "No reliever medication fixture" unless reliever
    dose = @user.dose_logs.create!(
      medication: reliever, puffs: 2,
      recorded_at: 2.days.ago.change(hour: 14)
    )
    get health_report_path
    assert_response :success
    assert_match "Dose Log", response.body
    assert_match reliever.name, response.body
    dose.destroy
  end

  test "GET /health-report shows empty states when no data in period" do
    # Destroy any readings/symptoms in the last 30 days for the verified user
    @user.peak_flow_readings.where(recorded_at: 30.days.ago..).destroy_all
    @user.symptom_logs.where(recorded_at: 30.days.ago..).destroy_all
    get health_report_path
    assert_response :success
    assert_match "No peak flow readings in this period", response.body
    assert_match "No symptoms logged in this period", response.body
  end

  test "GET /appointment-summary redirects to /health-report" do
    get "/appointment-summary"
    assert_response :redirect
    assert_redirected_to "/health-report"
  end

  test "GET /health-report displays 30-Day Health Report title" do
    get health_report_path
    assert_response :success
    assert_match "30-Day Health Report", response.body
  end

  test "GET /health-report displays plain Status label not GINA or Guideline limit" do
    get health_report_path
    assert_response :success
    assert_match "Status", response.body
    assert_no_match "GINA", response.body
    assert_no_match "Guideline limit", response.body
  end
end
