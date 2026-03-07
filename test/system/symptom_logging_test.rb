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

  # Helper: sign in as a given user via the login form.
  # Waits for the redirect to root to ensure session cookie is set before continuing.
  def sign_in_as(user, password: "password123")
    visit new_session_url
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    # Wait for redirect away from sign-in page to confirm session is established
    assert_current_path root_url
  end

  # --- CORE LOGGING FLOW ---

  test "logged-in user can log a symptom and it appears in the list" do
    sign_in_as @alice

    visit symptom_logs_url

    # Fill in the form
    select "Wheezing", from: "Symptom type"
    select "Moderate", from: "Severity"
    # recorded_at is pre-filled with current time — leave as is

    click_button "Log symptom"

    # Entry appears in the list without a full page load
    assert_text "Wheezing"
    assert_text "Moderate"
  end

  test "form clears after successful submission" do
    sign_in_as @alice
    visit symptom_logs_url

    select "Coughing", from: "Symptom type"
    select "Mild", from: "Severity"
    click_button "Log symptom"

    # Form is cleared — symptom type select should be back to the blank prompt
    within("turbo-frame#symptom_log_form") do
      assert_selector "option[selected]", count: 0
    end
  end

  test "notes are saved and appear in the entry list" do
    sign_in_as @alice
    visit symptom_logs_url

    select "Chest tightness", from: "Symptom type"
    select "Severe", from: "Severity"

    # Lexxy renders a <lexxy-editor> custom element via JavaScript.
    # Wait up to 10 seconds for it to finish booting before interacting.
    lexxy_editor = find("lexxy-editor [data-lexical-editor]", wait: 10)
    lexxy_editor.click
    lexxy_editor.send_keys "Triggered by cold air outside"

    click_button "Log symptom"

    assert_text "Chest tightness"
    assert_text "Triggered by cold air outside"
  end

  test "validation error appears inline without leaving the page" do
    sign_in_as @alice
    visit symptom_logs_url

    # The selects have HTML5 `required` which triggers browser-native validation.
    # Remove `required` via JS to force submission to the server so Rails validation fires.
    execute_script("document.querySelectorAll('select[required]').forEach(el => el.removeAttribute('required'))")
    execute_script("document.querySelectorAll('input[required]').forEach(el => el.removeAttribute('required'))")

    # Submit with no selections (blank symptom type and severity)
    click_button "Log symptom"

    # Rails validation error message appears on the same page via Turbo Stream
    assert_text "error"
    # Still on symptom logs page
    assert_current_path symptom_logs_url
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

  # --- EDIT FLOW ---

  test "user can edit an existing symptom entry inline" do
    # Use the alice_wheezing fixture — it already exists in the list
    entry = symptom_logs(:alice_wheezing)

    sign_in_as @alice
    visit symptom_logs_url

    # The entry should be visible
    assert_selector "##{dom_id(entry)}"

    # Click the Edit button within this entry's turbo frame
    within("##{dom_id(entry)}") do
      click_link "Edit"
    end

    # The edit form should now appear inline inside the same frame
    within("##{dom_id(entry)}") do
      assert_selector "form"
      select "Chest tightness", from: "Symptom type"
      select "Severe", from: "Severity"
      click_button "Update symptom"
    end

    # After save, the entry in the list shows updated values
    within("##{dom_id(entry)}") do
      assert_text "Chest tightness"
      assert_text "Severe"
      # The edit form is gone — only the entry display (no form inputs visible)
      assert_no_selector "input, select[name='symptom_log[symptom_type]']"
    end
  end

  # --- DELETE FLOW ---

  test "user can delete a symptom entry and it disappears from the list" do
    entry = symptom_logs(:alice_wheezing)

    sign_in_as @alice
    visit symptom_logs_url

    assert_selector "##{dom_id(entry)}"

    # Dismiss the browser confirm dialog (accept it)
    # Capybara handles data-turbo-confirm via the browser's native dialog.
    # accept_confirm wraps the action that triggers the dialog.
    accept_confirm "Delete this entry?" do
      within("##{dom_id(entry)}") do
        click_button "Delete"
      end
    end

    # Entry no longer in the DOM
    assert_no_selector "##{dom_id(entry)}"
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

    # The timeline section must be visible
    assert_selector "section[aria-label='Symptom timeline']"

    # Click the "7 days" chip — should update timeline_content frame
    within(".filter-bar") { click_on "7 days" }
    # Active chip state must update (filter_bar now inside the frame)
    assert_selector ".filter-chip--active", text: "7 days"

    # alice_coughing_old (40 days ago) should not be in the updated list
    assert_no_selector ".timeline-row", text: /Coughing/i

    # Page heading still present — confirms no full page reload wiped the form section
    assert_selector "h1", text: "Log a Symptom"
  end

  test "trend bar shows severity counts above entry list" do
    sign_in_as users(:verified_user)
    visit symptom_logs_path

    # Trend bar rendered (Alice has entries of varied severity)
    assert_selector ".trend-bar"

    # At least one segment present
    assert_selector ".trend-segment"
  end

  test "All chip shows entries from every date" do
    sign_in_as users(:verified_user)
    visit symptom_logs_path

    within(".filter-bar") { click_on "All" }

    # alice_coughing_old (40 days ago) should now appear
    assert_selector ".timeline-row", text: /Coughing/i
  end

  test "empty state shown when no entries match filter" do
    # Sign in as verified_user and use a future date range that has no entries
    sign_in_as users(:verified_user)
    visit symptom_logs_path(start_date: 1.year.from_now.to_date.to_s, end_date: 2.years.from_now.to_date.to_s)

    assert_selector ".timeline-empty-state"
  end
end
