# frozen_string_literal: true

require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  # Use new_user (neither flag set) for most tests
  setup do
    @new_user = users(:new_user)
    sign_in_as @new_user
  end

  # -- Dashboard guard tests --

  test "GET /dashboard redirects new user (no flags) to onboarding" do
    get dashboard_path
    assert_redirected_to onboarding_step_path(1)
  end

  test "GET /dashboard does NOT redirect returning user (both flags true)" do
    sign_in_as users(:verified_user)
    get dashboard_path
    assert_response :success
  end

  test "GET /dashboard redirects user with only personal_best_done=true to onboarding" do
    @new_user.update!(onboarding_personal_best_done: true)
    get dashboard_path
    assert_redirected_to onboarding_step_path(1)
  end

  # -- OnboardingController guard --

  test "step 1 redirects to step 2 if personal best already done" do
    users(:new_user).update!(onboarding_personal_best_done: true)
    get onboarding_step_path(1)
    assert_redirected_to onboarding_step_path(2)
  end

  test "GET /onboarding/step/1 redirects to dashboard when both flags true" do
    sign_in_as users(:verified_user)
    get onboarding_step_path(1)
    assert_redirected_to dashboard_path
  end

  test "GET /onboarding/step/1 renders for new user" do
    get onboarding_step_path(1)
    assert_response :success
  end

  test "GET /onboarding/step/2 renders for new user" do
    get onboarding_step_path(2)
    assert_response :success
  end

  # -- Step 1 complete --

  test "POST submit_1 with valid value sets personal_best_done flag and redirects to step 2" do
    assert_difference "@new_user.personal_best_records.count", 1 do
      post onboarding_submit_1_path, params: { personal_best_record: { value: 450 } }
    end
    assert_redirected_to onboarding_step_path(2)
    assert @new_user.reload.onboarding_personal_best_done?
  end

  test "POST submit_1 with invalid value re-renders step 1 without setting flag" do
    post onboarding_submit_1_path, params: { personal_best_record: { value: 50 } }
    assert_response :unprocessable_entity
    assert_not @new_user.reload.onboarding_personal_best_done?
  end

  # -- Step 2 complete --

  test "POST submit_2 with valid params sets medication_done flag and redirects to dashboard" do
    assert_difference "@new_user.medications.count", 1 do
      post onboarding_submit_2_path, params: {
        medication: {
          name: "Ventolin",
          medication_type: "reliever",
          standard_dose_puffs: 2,
          starting_dose_count: 200
        }
      }
    end
    assert_redirected_to dashboard_path
    assert @new_user.reload.onboarding_medication_done?
  end

  test "POST submit_2 with invalid params re-renders step 2 without setting flag" do
    post onboarding_submit_2_path, params: { medication: { name: "" } }
    assert_response :unprocessable_entity
    assert_not @new_user.reload.onboarding_medication_done?
  end

  # -- Skip step 1 --

  test "PATCH skip step 1 sets personal_best_done flag and redirects to step 2" do
    patch onboarding_skip_path(1)
    assert_redirected_to onboarding_step_path(2)
    assert @new_user.reload.onboarding_personal_best_done?
  end

  # -- Skip step 2 --

  test "PATCH skip step 2 after completing step 1 — flash notice present" do
    @new_user.update!(onboarding_personal_best_done: true)
    patch onboarding_skip_path(2)
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_equal "You can complete setup any time from Settings.", flash[:notice]
    assert @new_user.reload.onboarding_medication_done?
  end

  test "PATCH skip both steps — both flags true and flash notice survives to dashboard" do
    patch onboarding_skip_path(2)
    assert_redirected_to dashboard_path
    assert @new_user.reload.onboarding_personal_best_done?
    assert @new_user.reload.onboarding_medication_done?
    follow_redirect!
    assert_equal "You can complete setup any time from Settings.", flash[:notice]
  end

  # -- Auth guard --

  test "GET /onboarding/step/1 redirects unauthenticated user to sign in" do
    sign_out
    get onboarding_step_path(1)
    assert_redirected_to new_session_path
  end
end
