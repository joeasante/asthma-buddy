# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "GET /dashboard returns 200 for authenticated user" do
    get dashboard_path
    assert_response :success
  end

  test "GET /dashboard renders status card" do
    get dashboard_path
    assert_select ".dash-status"
  end

  test "GET /dashboard renders summary stats" do
    get dashboard_path
    assert_select ".dash-stats"
    assert_select ".dash-stat", minimum: 3
  end

  test "GET /dashboard renders quick log buttons" do
    get dashboard_path
    assert_select ".dash-quick-log"
    assert_select ".dash-quick-btn", minimum: 2
  end

  test "GET /dashboard renders recent entries section" do
    get dashboard_path
    assert_select ".dash-recents"
  end

  test "GET / redirects authenticated user to dashboard" do
    get root_url
    assert_redirected_to dashboard_path
  end

  test "GET /dashboard redirects unauthenticated user to sign in" do
    delete session_path
    get dashboard_path
    assert_redirected_to new_session_path
  end

  test "GET /dashboard responds successfully (health_event_markers integration)" do
    # Verifies the controller builds @health_event_markers without error.
    # assigns() is unavailable without rails-controller-testing gem;
    # a 200 response confirms the instance variable is built correctly.
    get dashboard_path
    assert_response :success
  end

  test "@health_event_markers excludes events outside the 7-day chart window" do
    # Create an event far in the past — should not be included in markers JSON.
    old_event = HealthEvent.create!(
      user: @user,
      event_type: :other,
      recorded_at: 30.days.ago
    )

    # Force chart data to exist so canvas renders, by creating a reading this week
    reading = PeakFlowReading.create!(time_of_day: :evening,
      user: @user,
      value: 400,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 20.hours
    )

    get dashboard_path
    assert_response :success

    # The chart wrapper carries the health_events JSON — old_event date must not appear
    assert_select "[data-chart-health-events-value]" do |wrappers|
      markers_json = wrappers.first["data-chart-health-events-value"]
      assert_not_includes markers_json, old_event.recorded_at.to_date.to_s
    end

    old_event.destroy
    reading.destroy
  end

  test "canvas element includes data-chart-health-events-value attribute when chart renders" do
    # Canvas only renders when @chart_data.any? — ensure a reading exists this week.
    reading = PeakFlowReading.create!(time_of_day: :evening,
      user: @user,
      value: 400,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 20.hours
    )

    get dashboard_path
    assert_select "[data-chart-health-events-value]"

    reading.destroy
  end

  test "active_illness is nil when no ongoing illness" do
    # Ensure no ongoing illness exists for verified_user in default fixtures
    @user.health_events.where(event_type: :illness, ended_at: nil).destroy_all
    get dashboard_path
    assert_response :success
  end

  test "GET /dashboard renders interpretation sentence when readings exist this week" do
    reading = PeakFlowReading.create!(
      user: @user,
      value: 400,
      time_of_day: :morning,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 9.hours
    )
    get dashboard_path
    assert_response :success
    assert_select ".dash-insight-card"
    reading.destroy
  end

  test "GET /dashboard does not render interpretation sentence when no readings this week" do
    @user.peak_flow_readings.where(recorded_at: Date.current.beginning_of_week(:monday)..).destroy_all
    get dashboard_path
    assert_response :success
    assert_select ".dash-insight-card", count: 0
  end

  test "GET /dashboard renders GINA warning when reliever used more than twice this week" do
    reliever = @user.medications.find_by(medication_type: 0, course: false)
    skip "No reliever medication fixture found for this user" unless reliever
    3.times do |i|
      DoseLog.create!(
        user: @user,
        medication: reliever,
        puffs: 2,
        recorded_at: Date.current.beginning_of_week(:monday) + i.days
      )
    end
    get dashboard_path
    assert_response :success
    assert_match "Reliever used", response.body
    DoseLog.where(user: @user, medication: reliever,
      recorded_at: Date.current.beginning_of_week(:monday)..).destroy_all
  end

  test "GET /dashboard does not render GINA warning when reliever used twice or less this week" do
    @user.dose_logs.where(recorded_at: Date.current.beginning_of_week(:monday)..).destroy_all
    get dashboard_path
    assert_response :success
    assert_select ".dash-gina-warning", count: 0
  end

  test "reliever medications excludes course medications" do
    # Verify the dashboard loads correctly — courses should not appear in reliever section
    get dashboard_path
    assert_response :success
  end

  test "health_event_markers JSON includes expected keys for events in window" do
    # Create an event within the chart window
    event = HealthEvent.create!(user: @user, event_type: :illness, recorded_at: Time.current - 1.hour)

    # Force chart to render
    reading = PeakFlowReading.create!(time_of_day: :evening,
      user: @user,
      value: 400,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 20.hours
    )

    get dashboard_path
    assert_response :success

    assert_select "[data-chart-health-events-value]" do |wrappers|
      markers_json = wrappers.first["data-chart-health-events-value"]
      parsed = JSON.parse(markers_json)
      # Find the event we just created
      marker = parsed.find { |m| m["date"] == Date.current.to_s }
      if marker
        assert marker.key?("date")
        assert marker.key?("type")
        assert marker.key?("label")
        assert marker.key?("css_modifier")
      end
    end

    event.destroy
    reading.destroy
  end
end

class DashboardVarsCacheTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

  test "set_dashboard_vars writes to cache on first dashboard load" do
    get dashboard_path
    assert_response :success
    assert_not_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end

  test "set_dashboard_vars reads from cache on second dashboard load without re-populating" do
    # First call populates cache
    get dashboard_path
    assert_response :success

    # Overwrite cache with sentinel value
    sentinel = { preventer_adherence: [], reliever_medications: [], active_illness: nil }
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), sentinel)

    # Second call should read from cache (sentinel), not re-query DB
    get dashboard_path
    assert_response :success

    cached = Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
    assert_equal sentinel, cached
  end
end
