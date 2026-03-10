# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  test "DELETE /account with correct confirmation destroys user and redirects to root" do
    assert_difference "User.count", -1 do
      delete settings_account_path, params: { confirmation: "DELETE" }
    end
    assert_redirected_to root_path
    assert_equal "Your account and all associated data have been permanently deleted.", flash[:notice]
  end

  test "DELETE /account with wrong confirmation does not destroy user" do
    assert_no_difference "User.count" do
      delete settings_account_path, params: { confirmation: "delete" }
    end
    assert_redirected_to settings_path
    assert_equal "Account not deleted. You must type DELETE exactly to confirm.", flash[:alert]
  end

  test "DELETE /account with empty confirmation does not destroy user" do
    assert_no_difference "User.count" do
      delete settings_account_path, params: { confirmation: "" }
    end
    assert_redirected_to settings_path
  end

  test "unauthenticated DELETE /account redirects to sign in" do
    sign_out
    delete settings_account_path, params: { confirmation: "DELETE" }
    assert_redirected_to new_session_path
  end

  test "deleted user cannot sign back in" do
    delete settings_account_path, params: { confirmation: "DELETE" }
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_redirected_to new_session_path
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "DELETE /account destroys all associated health data" do
    # Create associated records for the test user so we have something to verify
    symptom_log = SymptomLog.create!(
      user: @user,
      symptom_type: :coughing,
      severity: :mild,
      recorded_at: 1.hour.ago
    )
    peak_flow = PeakFlowReading.create!(
      user: @user,
      value: 400,
      time_of_day: :morning,
      recorded_at: 1.hour.ago
    )

    user_id = @user.id

    delete settings_account_path, params: { confirmation: "DELETE" }

    assert_equal 0, SymptomLog.where(user_id: user_id).count
    assert_equal 0, PeakFlowReading.where(user_id: user_id).count
    assert_equal 0, DoseLog.where(user_id: user_id).count
    assert_equal 0, Medication.where(user_id: user_id).count
    assert_equal 0, HealthEvent.where(user_id: user_id).count
    assert_equal 0, PersonalBestRecord.where(user_id: user_id).count
  end
end
