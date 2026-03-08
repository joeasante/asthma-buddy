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

  test "user can log a dose from the medication card and it appears in dose history" do
    sign_in_as @alice
    visit settings_medications_url

    # The medication card for Ventolin (alice_reliever) is visible
    within("##{dom_id(@medication)}") do
      # Puffs field is pre-filled with standard_dose_puffs (2)
      assert_selector "input[name='dose_log[puffs]']"

      fill_in "Puffs taken", with: "2"
      click_button "Log dose"
    end

    # Flash confirms the save
    assert_text "Dose logged."

    # The dose log entry appears in the recent doses section
    within("#dose_history_#{dom_id(@medication)}") do
      assert_text "2 puffs"
    end
  end

  test "remaining dose count decreases after logging a dose" do
    sign_in_as @alice
    visit settings_medications_url

    # Read the current remaining count displayed on the card
    # alice_reliever: starting_dose_count 200, fixture logs total 4 puffs (dose_1: 2, dose_2: 2)
    # remaining_doses = 200 - 4 = 196
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "196 doses"
    end

    # Log 2 more puffs
    within("##{dom_id(@medication)}") do
      fill_in "Puffs taken", with: "2"
      click_button "Log dose"
    end

    # Remaining count should now be 194
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "194 doses"
    end
  end

  # --- DELETE A DOSE ---

  test "user can delete a dose log entry and it disappears from dose history" do
    # alice_reliever_dose_1 and alice_reliever_dose_2 are already in fixtures
    dose_log = dose_logs(:alice_reliever_dose_1)

    sign_in_as @alice
    visit settings_medications_url

    # Dose entry is visible in the history
    within("#dose_history_#{dom_id(@medication)}") do
      assert_selector "##{dom_id(dose_log)}"

      # Click Delete on this specific entry
      within("##{dom_id(dose_log)}") do
        click_button "Delete"
      end
    end

    # Confirm via the custom dialog
    confirm_dialog

    # Dose entry is gone from the history
    within("#dose_history_#{dom_id(@medication)}") do
      assert_no_selector "##{dom_id(dose_log)}"
    end

    # Flash confirms the removal
    assert_text "Dose removed."
  end

  test "remaining dose count increases after deleting a dose log entry" do
    dose_log = dose_logs(:alice_reliever_dose_1)

    sign_in_as @alice
    visit settings_medications_url

    # Confirm starting remaining count (200 - 4 = 196)
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "196 doses"
    end

    # Delete dose_log with 2 puffs
    within("#dose_history_#{dom_id(@medication)}") do
      within("##{dom_id(dose_log)}") do
        click_button "Delete"
      end
    end
    confirm_dialog

    # Remaining count should now be 198 (200 - 2 remaining logs)
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "198 doses"
    end
  end

  # --- UNAUTHENTICATED ---

  test "unauthenticated user is redirected to sign in when visiting medications" do
    visit settings_medications_url
    assert_current_path new_session_url
  end
end
