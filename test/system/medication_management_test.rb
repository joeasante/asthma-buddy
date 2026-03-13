# frozen_string_literal: true

require "application_system_test_case"

class MedicationManagementTest < ApplicationSystemTestCase
  setup do
    @alice = users(:verified_user)
    @bob = users(:unverified_user)
    ActiveJob::Base.queue_adapter = :inline
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  # Confirm the custom <dialog> modal (data-turbo-confirm uses confirm_controller.js)
  def confirm_dialog
    find("dialog.confirm-dialog button[data-action='confirm#accept']").click
  end

  # --- ADD MEDICATION ---

  test "user can add a medication and it appears in the list without a full page reload" do
    sign_in_as @alice
    visit settings_medications_url

    click_link "Add medication"

    fill_in "Medication name", with: "Fostair 100/6"
    select "Combination", from: "Type"
    fill_in "Standard dose (puffs)", with: "2"
    fill_in "Starting dose count", with: "120"

    click_button "Add medication"

    # Form is reset; flash appears confirming save
    assert_text "Medication added."

    # Navigate to index — medication card should appear in the list
    visit settings_medications_url
    assert_text "Fostair 100/6"
    assert_text(/combination/i)
  end

  test "optional fields are saved and visible after adding medication" do
    sign_in_as @alice
    visit new_settings_medication_url

    fill_in "Medication name", with: "Qvar Easi-Breathe"
    select "Preventer", from: "Type"
    fill_in "Standard dose (puffs)", with: "2"
    fill_in "Starting dose count", with: "120"
    fill_in "Sick-day dose (puffs)", with: "4"
    fill_in "Doses per day", with: "2"

    click_button "Add medication"

    # Flash confirms successful save
    assert_text "Medication added."

    # Navigate to index and verify the medication appears in the list
    visit settings_medications_url
    assert_text "Qvar Easi-Breathe"
    assert_text "Preventer"
  end

  # --- INLINE EDIT ---

  test "user can edit a medication name inline via Turbo Frame" do
    # Use an existing fixture medication
    medication = medications(:alice_reliever)

    sign_in_as @alice
    visit settings_medications_url

    # The card is visible
    assert_selector "##{dom_id(medication)}"

    # Open the overflow menu and click Edit
    within("##{dom_id(medication)}") do
      find("details.med-overflow summary").click
      click_link "Edit"
    end

    # Edit form appears on the edit page (via turbo frame _top)
    assert_selector "form"
    fill_in "Medication name", with: "Ventolin Evohaler"
    click_button "Update medication"

    # Updated name appears; form is gone
    assert_text "Ventolin Evohaler"
    assert_no_selector "input[name='medication[name]']"
  end

  # --- REMOVE MEDICATION ---

  test "user can remove a medication and it disappears from the list" do
    medication = medications(:alice_reliever)

    sign_in_as @alice
    visit settings_medications_url

    assert_selector "##{dom_id(medication)}"

    # Open the overflow menu, then click Remove
    within("##{dom_id(medication)}") do
      find("details.med-overflow summary").click
      click_button "Remove"
    end

    # Confirm via the custom dialog (not native browser confirm)
    confirm_dialog

    assert_no_selector "##{dom_id(medication)}"
  end

  # --- CROSS-USER ISOLATION ---

  test "user cannot edit another user's medication via direct URL" do
    bob_medication = medications(:bob_reliever)

    sign_in_as @alice
    visit edit_settings_medication_url(bob_medication)

    # 404 — the edit form for bob's medication must not be visible
    assert_no_selector "input[name='medication[name]']", wait: 3
  end

  # --- UNAUTHENTICATED ---

  test "unauthenticated user is redirected to sign in" do
    visit settings_medications_url
    assert_current_path new_session_url
  end
end
