# frozen_string_literal: true

require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  # System tests run in a separate Puma thread; disabling transactional tests
  # ensures DB changes from browser actions are committed and visible across
  # all connections. Cleanup is handled explicitly in teardown.
  self.use_transactional_tests = false

  setup do
    # Reset charlie's onboarding flags before each test in case a previous test
    # left them set (no transaction rollback when use_transactional_tests = false).
    User.where(email_address: "charlie@example.com")
        .update_all(onboarding_personal_best_done: false, onboarding_medication_done: false)

    @new_user = User.find_by!(email_address: "charlie@example.com")

    # Sign in as charlie (new_user). After sign-in, charlie is redirected to
    # the onboarding wizard (both flags false). We sign in via the form since
    # charlie is not onboarded and lands on the wizard, not the dashboard.
    visit new_session_url
    fill_in "Email address", with: @new_user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
    # Wait for the page to navigate away from the sign-in form.
    # Charlie lands at either the onboarding wizard or dashboard.
    # If still at sign-in after wait, authentication may have failed — check for
    # "What's your personal best?" which confirms we reached the onboarding wizard.
    assert_text "What's your personal best?", wait: 15
  end

  teardown do
    # Clean up any sessions, personal_best_records, medications created during test
    @new_user&.sessions&.delete_all
    @new_user&.personal_best_records&.delete_all
    @new_user&.medications&.destroy_all
    # Reset flags for alice (verified_user) in case any test modified them
    User.where(email_address: "alice@example.com")
        .update_all(onboarding_personal_best_done: true, onboarding_medication_done: true)
  end

  test "new user visiting dashboard is redirected to onboarding wizard" do
    visit dashboard_path
    assert_current_path onboarding_step_path(1)
    assert_text "What's your personal best?"
  end

  test "complete onboarding wizard: set personal best then add medication" do
    visit dashboard_path
    # Step 1
    assert_text "What's your personal best?", wait: 10
    fill_in "Personal best (L/min)", with: "450"
    click_on "Save and continue"

    # Step 2
    assert_text "Add your inhaler", wait: 10
    fill_in "Medication name", with: "Ventolin"
    fill_in "Puffs per dose", with: "2"
    click_on "Save and continue"

    # Dashboard
    assert_current_path dashboard_path
    assert_text "Welcome to Asthma Buddy"
  end

  test "skip step 1 then complete step 2" do
    visit onboarding_step_path(1)
    click_on "Skip this step"

    assert_text "Add your inhaler", wait: 10
    fill_in "Medication name", with: "Ventolin"
    fill_in "Puffs per dose", with: "2"
    click_on "Save and continue"

    assert_current_path dashboard_path
    assert @new_user.reload.onboarding_personal_best_done?
    assert @new_user.reload.onboarding_medication_done?
  end

  test "complete step 1 then skip step 2" do
    visit onboarding_step_path(1)
    fill_in "Personal best (L/min)", with: "500"
    click_on "Save and continue"

    assert_text "Add your inhaler", wait: 10
    click_on "Skip this step"

    assert_current_path dashboard_path
    assert @new_user.reload.onboarding_personal_best_done?
    assert @new_user.reload.onboarding_medication_done?
  end

  test "skip both steps lands on dashboard" do
    visit onboarding_step_path(1)
    click_on "Skip this step"

    # Wait for Step 2 to appear before skipping it, avoiding a timing issue
    # where the second click fires before the page transitions to Step 2.
    assert_text "Add your inhaler", wait: 5
    click_on "Skip this step"

    assert_current_path dashboard_path
    assert @new_user.reload.onboarding_personal_best_done?
    assert @new_user.reload.onboarding_medication_done?
  end

  test "returning user with both flags set visits dashboard directly" do
    sign_in_as users(:verified_user)
    visit dashboard_path
    assert_current_path dashboard_path
    assert_no_text "What's your personal best?"
  end

  test "progress indicator shows 2 steps" do
    visit onboarding_step_path(1)
    # The progress bar has aria-valuemax="2"
    assert_selector "[aria-valuemax='2']"
  end
end
