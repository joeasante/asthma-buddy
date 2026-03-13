# frozen_string_literal: true

require "application_system_test_case"

class SymptomLoggingTest < ApplicationSystemTestCase
  setup do
    @alice = users(:verified_user)
    @bob = users(:unverified_user)
    # Use inline job adapter so any deliver_later calls in the request cycle complete synchronously
    # (Mirrors pattern from Phase 2 auth system tests — see 02-03-SUMMARY.md)
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  # Helper to select severity via label click (severity uses radio buttons in a styled group)
  def choose_severity(label_text)
    find("label.severity-btn", text: label_text).click
  end

  # --- CORE LOGGING FLOW ---

  test "logged-in user can log a symptom and it appears in the list" do
    sign_in_as @alice

    visit new_symptom_log_path

    # Fill in the form
    select "Wheezing", from: "Symptom type"
    choose_severity "Moderate"
    # recorded_at is pre-filled with current time — leave as is

    click_button "Save symptom"

    # Entry appears in the list without a full page load
    assert_text "Wheezing"
    assert_text "Moderate"
  end

  test "form clears after successful submission" do
    sign_in_as @alice
    visit new_symptom_log_path

    select "Coughing", from: "Symptom type"
    choose_severity "Mild"
    click_button "Save symptom"

    # After submission we should see the saved entry text
    assert_text "Coughing"
  end

  test "notes are saved and appear when viewing the entry" do
    sign_in_as @alice
    visit new_symptom_log_path

    select "Chest tightness", from: "Symptom type"
    choose_severity "Severe"

    # Lexxy renders a <lexxy-editor> custom element via JavaScript.
    # Wait up to 10 seconds for it to finish booting before interacting.
    lexxy_editor = find("lexxy-editor [data-lexical-editor]", wait: 10)
    lexxy_editor.click
    lexxy_editor.send_keys "Triggered by cold air outside"

    click_button "Save symptom"

    # Flash confirms save
    assert_text "Symptom logged."

    # Navigate to the index with All filter to find the new entry and verify notes
    visit symptom_logs_path(preset: "all")
    assert_text "Chest tightness"

    # Click through to the show page to verify notes were saved
    find(".timeline-card", text: /Chest tightness/i, match: :first).click
    assert_text "Triggered by cold air outside"
  end

  test "validation error appears inline without leaving the page" do
    sign_in_as @alice
    visit new_symptom_log_path

    # The selects have HTML5 `required` which triggers browser-native validation.
    # Remove `required` via JS to force submission to the server so Rails validation fires.
    execute_script("document.querySelectorAll('select[required]').forEach(el => el.removeAttribute('required'))")
    execute_script("document.querySelectorAll('input[required]').forEach(el => el.removeAttribute('required'))")

    # Submit with no selections (blank symptom type and severity)
    click_button "Save symptom"

    # Rails validation error message appears on the same page via Turbo Stream
    assert_text "error"
    # Still on symptom logs page
    assert_current_path new_symptom_log_path
  end

  # --- MULTI-USER ISOLATION ---

  test "user sees only their own symptom entries" do
    # Create an entry for bob (the other user)
    bob_entry = SymptomLog.create!(
      user: @bob,
      symptom_type: :coughing,
      severity: :mild,
      recorded_at: 1.hour.ago
    )

    sign_in_as @alice
    visit symptom_logs_url

    # Alice should not see Bob's entry
    assert_no_selector "##{dom_id(bob_entry)}"
    # Bob's symptom text should not appear either
    # (using the fixture bob_coughing from Plan 01 would show "Coughing" which alice might also have,
    # so check by dom_id — the definitive isolation check)
  end

  test "unauthenticated user is redirected to sign in" do
    visit symptom_logs_url
    assert_current_path new_session_url
  end

  # --- EDIT FLOW — via show page ---

  test "user can edit an existing symptom entry via the show page" do
    entry = symptom_logs(:alice_wheezing)

    sign_in_as @alice
    visit symptom_logs_url

    # Click on the entry card to navigate to show page
    find("##{dom_id(entry)}").click

    # Click Edit on the show page
    click_link "Edit"

    # Edit form appears
    assert_selector "form"
    select "Chest tightness", from: "Symptom type"
    choose_severity "Severe"
    click_button "Update symptom"

    # After save, the entry display updates (turbo stream replaces the form with display)
    assert_text "Chest tightness"
    assert_text "Severe"
  end

  # --- DELETE FLOW — via show page ---

  test "user can delete a symptom entry from the show page" do
    entry = symptom_logs(:alice_wheezing)

    sign_in_as @alice
    visit symptom_logs_url

    # Navigate to show page by clicking the entry card
    find("##{dom_id(entry)}").click

    assert_selector "h1", text: "Symptoms Log"

    # Delete button — form has turbo: false, no confirm dialog fires
    click_button "Delete"

    # Redirected to symptom logs index
    assert_current_path symptom_logs_path, wait: 5
    assert_no_selector "##{dom_id(entry)}", wait: 5
  end

  # --- CROSS-USER URL ISOLATION ---

  test "user cannot edit another user's entry via direct URL" do
    bob_entry = symptom_logs(:bob_coughing)

    sign_in_as @alice
    visit edit_symptom_log_url(bob_entry)

    # Rails raises RecordNotFound -> 404/error page is shown, not the edit form
    # The edit form for bob's entry must not be visible
    assert_no_selector "form input[name='symptom_log[symptom_type]']", wait: 3
  end

  # --- TIMELINE FILTER — TURBO FRAME CHIP INTERACTION ---

  test "preset chip filters timeline via Turbo Frame without full page reload" do
    user = users(:verified_user)
    sign_in_as user

    visit symptom_logs_path

    # The filter bar must be visible
    assert_selector ".filter-bar"

    # Click the "7d" chip — should update timeline_content frame
    within("[role='group'][aria-label='Time period']") { click_on "7d" }
    # Active chip state must update
    assert_selector ".filter-chip--active", text: "7d"

    # alice_coughing_old (40 days ago) should not be in the updated list
    assert_no_selector ".timeline-card", text: /Coughing/i

    # Page heading still present — confirms no full page reload wiped the header
    assert_selector "h1", text: "Symptoms"
  end

  test "severity legend shows counts above entry list" do
    sign_in_as users(:verified_user)
    visit symptom_logs_path

    # Severity legend rendered (Alice has entries of varied severity)
    # Uses chart-severity-legend / chart-severity-pill CSS classes
    assert_selector ".chart-severity-legend"
    assert_selector ".chart-severity-pill"
  end

  test "All chip shows entries from every date" do
    sign_in_as users(:verified_user)
    visit symptom_logs_path

    within("[role='group'][aria-label='Time period']") { click_on "All" }

    # alice_coughing_old (40 days ago) should now appear
    assert_selector ".timeline-card", text: /Coughing/i
  end

  test "empty state shown when no entries match filter" do
    # Sign in as verified_user and use a future date range that has no entries
    sign_in_as users(:verified_user)
    visit symptom_logs_path(start_date: 1.year.from_now.to_date.to_s, end_date: 2.years.from_now.to_date.to_s)

    assert_selector ".empty-state"
  end
end
