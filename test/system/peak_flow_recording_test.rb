# frozen_string_literal: true

require "application_system_test_case"

class PeakFlowRecordingTest < ApplicationSystemTestCase
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "user can log a peak flow reading and see zone feedback" do
    # alice has personal best records: 500 (30 days ago) and 520 (7 days ago)
    # Visit the entry form
    visit new_peak_flow_reading_path
    assert_text "Record a reading"

    # Banner should NOT appear (alice has personal best)
    assert_no_css ".pf-form-banner"

    # Fill in the form
    fill_in "Reading value", with: "450"
    # recorded_at has a default value — leave it (already set to Time.current)

    click_button "Save reading"

    # Flash message should appear with zone info
    # 450 / 520 = 86.5% => Green Zone
    assert_text "Reading saved"
    assert_text "Green zone"
  end

  test "banner appears when user has no personal best" do
    PersonalBestRecord.where(user: @user).destroy_all
    visit new_peak_flow_reading_path

    assert_css ".pf-form-banner"
    assert_text "set your personal best"
  end

  test "user sees 'set your personal best' flash when no personal best exists" do
    PersonalBestRecord.where(user: @user).destroy_all
    visit new_peak_flow_reading_path

    fill_in "Reading value", with: "400"
    click_button "Save reading"

    assert_text "set your personal best"
  end

  test "validation error appears for blank reading value" do
    visit new_peak_flow_reading_path

    # Remove HTML5 required attribute so the server validation fires
    execute_script("document.querySelectorAll('input[required]').forEach(el => el.removeAttribute('required'))")

    # Leave value blank and submit
    click_button "Save reading"

    assert_text "error"
    assert_text "Value"
  end

  test "user can set personal best on profile page and banner disappears on form" do
    PersonalBestRecord.where(user: @user).destroy_all

    # Visit profile and set personal best
    visit profile_path
    fill_in "Enter your personal best", with: "520"
    click_button "Set personal best"

    assert_text "520"

    # Now visit the peak flow entry form — banner should be gone
    visit new_peak_flow_reading_path
    assert_no_css ".pf-form-banner"
  end
end
