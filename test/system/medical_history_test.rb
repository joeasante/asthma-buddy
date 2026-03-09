# frozen_string_literal: true

require "application_system_test_case"

class MedicalHistoryTest < ApplicationSystemTestCase
  setup do
    @alice = users(:verified_user)
    @bob   = users(:unverified_user)
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  def confirm_dialog
    find("dialog.confirm-dialog button[data-action='confirm#accept']").click
  end

  # --- NAVIGATION AND INDEX ---

  test "user can visit Medical History page" do
    sign_in_as @alice
    visit health_events_url
    assert_selector "h1", text: "Medical History"
  end

  # --- ADD EVENT (duration type — illness) ---

  test "user can add an illness event and it appears in the list" do
    sign_in_as @alice
    visit health_events_url

    click_link "Add event"

    assert_current_path new_health_event_url

    select "Illness", from: "Event type"
    # recorded_at is pre-filled — clear and set an explicit value to avoid test flakiness
    fill_in "Date", with: "2026-01-15T10:00"  # datetime-local format

    click_button "Save event"

    assert_current_path health_events_url
    assert_text "Medical event recorded."
    # Event badge uses CSS text-transform: uppercase — match case-insensitively
    assert_text(/illness/i)
  end

  # --- ADD EVENT (point-in-time type — GP appointment) ---

  test "user can add a GP appointment event" do
    sign_in_as @alice
    visit new_health_event_url

    select "GP appointment", from: "Event type"
    fill_in "Date", with: "2026-01-20T14:30"

    click_button "Save event"

    assert_current_path health_events_url
    # Event badge uses CSS text-transform: uppercase — match case-insensitively
    assert_text(/gp appointment/i)
  end

  # --- EDIT EVENT ---

  test "user can edit an existing event" do
    event = health_events(:alice_gp_appointment)
    sign_in_as @alice
    visit health_events_url

    within("##{dom_id(event)}") do
      click_link "Edit"
    end

    assert_selector "h1", text: "Edit medical event"

    # Change type to "Other"
    select "Other", from: "Event type"
    click_button "Update event"

    assert_current_path health_events_url
    assert_text "Medical event updated."
    # Event badge uses CSS text-transform: uppercase — match case-insensitively
    assert_text(/other/i)
  end

  # --- DELETE EVENT ---

  test "user can delete an event and it disappears from the list" do
    event = health_events(:alice_medication_change)
    sign_in_as @alice
    visit health_events_url

    assert_selector "##{dom_id(event)}"

    within("##{dom_id(event)}") do
      click_button "Delete"
    end

    confirm_dialog

    assert_no_selector "##{dom_id(event)}"
    assert_text "Medical event deleted."
  end

  # --- POINT-IN-TIME DISPLAY (gp_appointment) ---

  test "point-in-time event shows a single datetime, not a date range" do
    event = health_events(:alice_gp_appointment)
    sign_in_as @alice
    visit health_events_url

    within("##{dom_id(event)}") do
      # Single <time> element visible — point-in-time format
      assert_selector "time", count: 1
      # No dash separator (would indicate date range)
      assert_no_text "–"
      # No ongoing badge
      assert_no_selector ".event-ongoing-badge"
    end
  end

  # --- DURATION EVENT WITH ended_at — SHOWS DATE RANGE ---

  test "resolved illness event shows a date range" do
    event = health_events(:alice_illness_resolved)
    sign_in_as @alice
    visit health_events_url

    within("##{dom_id(event)}") do
      # Two <time> elements for start and end
      assert_selector "time", count: 2
      # Dash separator present
      assert_text "–"
      assert_no_selector ".event-ongoing-badge"
    end
  end

  # --- DURATION EVENT WITHOUT ended_at — SHOWS ONGOING BADGE ---

  test "ongoing illness event shows Ongoing badge" do
    event = health_events(:alice_illness_ongoing)
    sign_in_as @alice
    visit health_events_url

    within("##{dom_id(event)}") do
      # Badge uses CSS text-transform: uppercase — match case-insensitively
      assert_selector ".event-ongoing-badge", text: /ongoing/i
      # Only one <time> element (start date only)
      assert_selector "time", count: 1
    end
  end

  # --- AUTH GUARD ---

  test "unauthenticated user is redirected to sign in" do
    visit health_events_url
    assert_current_path new_session_url
  end

  # --- CROSS-USER URL ISOLATION ---

  test "user cannot access another user's event edit page" do
    bob_event = health_events(:bob_hospital)
    sign_in_as @alice
    visit edit_health_event_url(bob_event)

    # RecordNotFound -> error page shown, edit form must not be present
    assert_no_selector "form select[name='health_event[event_type]']", wait: 3
  end

  # --- CHART MARKER INTEGRATION ---

  test "health event markers appear in dashboard chart section when events exist in window" do
    # Create an event within the current chart window (this week, Mon–today)
    event = HealthEvent.create!(
      user: @alice,
      event_type: :gp_appointment,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 12.hours
    )

    # Ensure peak flow reading exists this week so the chart section renders
    reading = PeakFlowReading.create!(
      user: @alice,
      value: 400,
      recorded_at: Date.current.beginning_of_week(:monday).to_datetime + 10.hours
    )

    sign_in_as @alice
    visit dashboard_url

    # The chart canvas section must be present
    within("section[aria-label='7-day peak flow chart']") do
      assert_selector "canvas[data-chart-health-events-value]"
      # The data attribute must contain our event's date
      canvas = find("canvas[data-chart-health-events-value]")
      markers_json = canvas["data-chart-health-events-value"]
      assert_includes markers_json, event.recorded_at.to_date.to_s
    end

    event.destroy
    reading.destroy
  end
end
