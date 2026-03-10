# frozen_string_literal: true

require "application_system_test_case"

class PeakFlowDisplayTest < ApplicationSystemTestCase
  setup do
    @alice = users(:verified_user)
    @bob   = users(:unverified_user)
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  # -----------------------------------------------------------------------
  # ZONE BADGE DISPLAY
  # -----------------------------------------------------------------------

  test "index shows green zone badge for green reading" do
    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    reading = peak_flow_readings(:alice_green_reading)
    within("##{dom_id(reading)}") do
      assert_selector ".zone-badge--green"
    end
  end

  test "index shows yellow zone badge for yellow reading" do
    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    reading = peak_flow_readings(:alice_yellow_reading)
    within("##{dom_id(reading)}") do
      assert_selector ".zone-badge--yellow"
    end
  end

  test "user sees only their own readings on index" do
    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    # Bob's reading must not appear
    assert_no_selector "##{dom_id(peak_flow_readings(:bob_reading))}"
  end

  # -----------------------------------------------------------------------
  # EDIT FLOW
  # -----------------------------------------------------------------------

  test "user can edit a reading inline and see zone badge update" do
    reading = peak_flow_readings(:alice_green_reading)

    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    # Reading row is visible
    assert_selector "##{dom_id(reading)}"

    # Click Edit inside the reading's turbo frame
    within("##{dom_id(reading)}") do
      click_link "Edit"
    end

    # Inline form appears inside the same frame
    within("##{dom_id(reading)}") do
      assert_selector "form"
      # Change value — keep it in green zone (>= 80% of personal best)
      # Alice's latest personal best applicable to this reading (recorded 7 days ago) is 520
      # 420 / 520 = 80.8% => still green
      fill_in "Reading value", with: "420"
      click_button "Save reading"
    end

    # Row updates without a full page reload
    # The page heading must still be visible (proves no full navigation)
    assert_selector "h1", text: "Peak Flow History"

    # Updated value appears in the row
    within("##{dom_id(reading)}") do
      assert_text "420"
      # Green zone badge still present (420 is still green)
      assert_selector ".zone-badge--green"
      # Form is gone
      assert_no_selector "input[name='peak_flow_reading[value]']"
    end
  end

  test "validation error shown inline for invalid edit value" do
    reading = peak_flow_readings(:alice_green_reading)

    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    within("##{dom_id(reading)}") do
      click_link "Edit"
      # Wait for the value field to be present before stripping HTML5 validation attrs
      assert_selector "input[name='peak_flow_reading[value]']"
    end

    # Strip browser-native HTML5 validation attributes so the form submits to the server.
    # Must run AFTER the edit form is fully in the DOM.
    execute_script(<<~JS)
      document.querySelectorAll('input').forEach(function(el) {
        el.removeAttribute('required');
        el.removeAttribute('min');
        el.removeAttribute('max');
      });
    JS

    # Submit a clearly invalid value (0 fails the greater_than: 0 validation server-side)
    within("##{dom_id(reading)}") do
      find("input[name='peak_flow_reading[value]']").set("0")
      click_button "Save reading"
    end

    # Validation error appears — still on the same page (URL retains preset param)
    assert_current_path peak_flow_readings_url(preset: "all")
    # Error message appears in the re-rendered form inside the reading's frame
    within("##{dom_id(reading)}") do
      assert_selector "[role='alert']", wait: 5
    end
  end

  # -----------------------------------------------------------------------
  # DELETE FLOW
  # -----------------------------------------------------------------------

  test "user can delete a reading and it is removed from the list" do
    reading = peak_flow_readings(:alice_yellow_reading)

    sign_in_as @alice
    visit peak_flow_readings_url(preset: "all")

    assert_selector "##{dom_id(reading)}"

    # Click Delete — the custom confirm dialog appears
    within("##{dom_id(reading)}") do
      click_button "Delete"
    end

    # Accept the confirm dialog.
    # The app uses a custom Stimulus dialog (data-controller="confirm").
    # The dialog renders as a <dialog> element with a .btn-confirm-delete button.
    find(".btn-confirm-delete", wait: 5).click

    # Row is removed from the DOM
    assert_no_selector "##{dom_id(reading)}", wait: 5
  end

  # -----------------------------------------------------------------------
  # CROSS-USER URL ISOLATION
  # -----------------------------------------------------------------------

  test "user cannot access another user's edit form via direct URL" do
    bob_reading = peak_flow_readings(:bob_reading)

    sign_in_as @alice
    visit edit_peak_flow_reading_url(bob_reading)

    # Rails raises RecordNotFound (404) — edit form must not appear
    assert_no_selector "input[name='peak_flow_reading[value]']", wait: 3
  end
end
