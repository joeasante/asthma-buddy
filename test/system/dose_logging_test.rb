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

    # alice_reliever: starting_dose_count 200, fixture logs total 26 puffs
    # (dose_1: 2, dose_2: 2, plus 4 weekly_3w logs * 2, plus 7 weekly_5w logs * 2 = 26)
    # remaining_doses = 200 - 26 = 174
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "174 doses"
    end

    # Open log panel and log 2 more puffs
    within("##{dom_id(@medication)}") do
      find("details.med-log-details summary").click
      fill_in "Puffs taken", with: "2"
      click_button "Log dose"
    end

    # Remaining count should now be 172
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "172 doses"
    end
  end

  # --- DOSE LOG COUNT VIA REFILL ---

  test "remaining dose count resets after refilling a medication" do
    sign_in_as @alice
    visit settings_medications_url

    # alice_reliever: 200 - 26 = 174 remaining
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "174 doses"
    end

    within("##{dom_id(@medication)}") do
      # Open overflow menu
      find("details.med-overflow summary").click
      # Open refill inside overflow
      find("details.med-refill-details summary").click
      fill_in "medication[starting_dose_count]", with: "100"
      click_button "Confirm refill"
    end

    # After refill, refilled_at is reset to now so dose log history before refill is excluded.
    # Remaining = new starting_dose_count - doses taken since refill = 100 - 0 = 100
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "100 doses"
    end
  end

  test "remaining dose count increases after setting a higher refill count" do
    sign_in_as @alice
    visit settings_medications_url

    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "174 doses"
    end

    within("##{dom_id(@medication)}") do
      find("details.med-overflow summary").click
      find("details.med-refill-details summary").click
      fill_in "medication[starting_dose_count]", with: "300"
      click_button "Confirm refill"
    end

    # After refill, refilled_at is reset so prior dose logs are excluded.
    # Remaining = 300 - 0 = 300
    within("#remaining_count_#{dom_id(@medication)}") do
      assert_text "300 doses"
    end
  end

  # --- UNAUTHENTICATED ---

  test "unauthenticated user is redirected to sign in when visiting medications" do
    visit settings_medications_url
    assert_current_path new_session_url
  end
end
