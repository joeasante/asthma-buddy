# frozen_string_literal: true

require "test_helper"

class SymptomLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @other_user = users(:unverified_user)
    sign_in_as(@user)
  end

  # --- INDEX ---

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get symptom_logs_url
    assert_redirected_to new_session_url
  end

  test "index renders for authenticated user" do
    get symptom_logs_url
    assert_response :success
    assert_select "h1", "Log a Symptom"
  end

  test "index shows only current user's symptom logs" do
    get symptom_logs_url
    assert_response :success
    assert_select "##{dom_id(symptom_logs(:alice_wheezing))}"
    # bob's entry must NOT appear
    assert_select "##{dom_id(symptom_logs(:bob_coughing))}", count: 0
  end

  # --- CREATE ---

  test "create saves a valid symptom log and responds with turbo stream" do
    assert_difference "SymptomLog.count", 1 do
      post symptom_logs_url,
        params: { symptom_log: { symptom_type: "coughing", severity: "moderate", recorded_at: Time.current } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "create scopes new entry to current user" do
    post symptom_logs_url,
      params: { symptom_log: { symptom_type: "wheezing", severity: "mild", recorded_at: Time.current } }
    assert_equal @user, SymptomLog.last.user
  end

  test "create with invalid params renders unprocessable_entity" do
    assert_no_difference "SymptomLog.count" do
      post symptom_logs_url,
        params: { symptom_log: { symptom_type: "", severity: "", recorded_at: "" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  test "create without authentication redirects to sign in" do
    sign_out
    post symptom_logs_url,
      params: { symptom_log: { symptom_type: "coughing", severity: "mild", recorded_at: Time.current } }
    assert_redirected_to new_session_url
  end
end
