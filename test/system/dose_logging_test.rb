# frozen_string_literal: true

require "application_system_test_case"

class DoseLoggingTest < ApplicationSystemTestCase
  setup do
    @alice = users(:verified_user)
    @medication = medications(:alice_reliever)
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  def sign_in_as(user, password: "password123")
    visit new_session_url
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    assert_current_path dashboard_url
  end

  # Confirm the custom <dialog> modal (same pattern as medication_management_test.rb)
  def confirm_dialog
    find("dialog.confirm-dialog button[data-action='confirm#accept']").click
  end

  # --- LOG A DOSE ---

  test "user can log a dose from the medication row and see the flash confirmation" do
    sign_in_as @alice
    visit settings_medications_url

    within("##{dom_id(@medication)}") do
      # Open the log dose panel via the summary button
      find("details.med-log-details summary").click

      assert_selector "input[name='dose_log[puffs]']"

      fill_in "Puffs taken", with: "2"
      click_button "Log dose"
    end

    # Flash confirms the save
    assert_text "Dose logged."
  end

  test "remaining dose count decreases after logging a dose" do
    sign_in_as @alice
    visit settings_medications_url

    # alice_reliever: starting_dose_count 200, fixture logs total 4 puffs (dose_1: 2, dose_2: 2)
    # remaining_doses = 200 - 4 = 196
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "196 doses"
    end

    # Open log panel and log 2 more puffs
    within("##{dom_id(@medication)}") do
      find("details.med-log-details summary").click
      fill_in "Puffs taken", with: "2"
      click_button "Log dose"
    end

    # Remaining count should now be 194
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "194 doses"
    end
  end

  # --- DOSE LOG COUNT VIA REFILL ---

  test "remaining dose count resets after refilling a medication" do
    sign_in_as @alice
    visit settings_medications_url

    # alice_reliever: 200 - 4 = 196 remaining
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "196 doses"
    end

    within("##{dom_id(@medication)}") do
      # Open overflow menu
      find("details.med-overflow summary").click
      # Open refill inside overflow
      find("details.med-refill-details summary").click
      fill_in "medication[starting_dose_count]", with: "100"
      click_button "Confirm refill"
    end

    # After refill, remaining count reflects new starting count minus existing logs
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "96 doses"
    end
  end

  test "remaining dose count increases after setting a higher refill count" do
    sign_in_as @alice
    visit settings_medications_url

    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "196 doses"
    end

    within("##{dom_id(@medication)}") do
      find("details.med-overflow summary").click
      find("details.med-refill-details summary").click
      fill_in "medication[starting_dose_count]", with: "300"
      click_button "Confirm refill"
    end

    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "296 doses"
    end
  end

  # --- UNAUTHENTICATED ---

  test "unauthenticated user is redirected to sign in when visiting medications" do
    visit settings_medications_url
    assert_current_path new_session_url
  end
end
