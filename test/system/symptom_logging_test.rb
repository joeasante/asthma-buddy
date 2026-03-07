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
end
