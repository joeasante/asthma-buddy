# frozen_string_literal: true

require "test_helper"

class SymptomLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @other_user = users(:unverified_user)
    sign_in_as(@user)
    @symptom_log = symptom_logs(:alice_wheezing)
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

  # --- EDIT ---

  test "edit renders for owner" do
    get edit_symptom_log_url(@symptom_log)
    assert_response :success
  end

  test "edit returns 404 for another user's entry" do
    other_log = symptom_logs(:bob_coughing)
    get edit_symptom_log_url(other_log)
    assert_response :not_found
  end

  test "edit redirects unauthenticated user to sign in" do
    sign_out
    get edit_symptom_log_url(@symptom_log)
    assert_redirected_to new_session_url
  end

  # --- UPDATE ---

  test "update saves valid changes and responds with turbo stream" do
    patch symptom_log_url(@symptom_log),
      params: { symptom_log: { severity: "severe" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "severe", @symptom_log.reload.severity
  end

  test "update with invalid params renders unprocessable_entity" do
    patch symptom_log_url(@symptom_log),
      params: { symptom_log: { symptom_type: "" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
  end

  test "update returns 404 for another user's entry" do
    other_log = symptom_logs(:bob_coughing)
    patch symptom_log_url(other_log),
      params: { symptom_log: { severity: "severe" } }
    assert_response :not_found
  end

  # --- DESTROY ---

  test "destroy removes the entry and responds with turbo stream" do
    assert_difference "SymptomLog.count", -1 do
      delete symptom_log_url(@symptom_log),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "destroy returns 404 for another user's entry" do
    other_log = symptom_logs(:bob_coughing)
    assert_no_difference "SymptomLog.count" do
      delete symptom_log_url(other_log),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :not_found
  end

  test "destroy redirects unauthenticated user to sign in" do
    sign_out
    delete symptom_log_url(@symptom_log)
    assert_redirected_to new_session_url
  end
end
