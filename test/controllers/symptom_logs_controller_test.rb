# frozen_string_literal: true

require "test_helper"

class SymptomLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @other_user = users(:unverified_user)
    sign_in_as(@user)
    @symptom_log = symptom_logs(:alice_wheezing)
  end

  # --- SHOW ---

  test "show renders for owner" do
    get symptom_log_url(@symptom_log)
    assert_response :success
  end

  test "show returns 404 for another user's entry" do
    get symptom_log_url(symptom_logs(:bob_coughing))
    assert_response :not_found
  end

  test "show redirects unauthenticated user to sign in" do
    sign_out
    get symptom_log_url(@symptom_log)
    assert_redirected_to new_session_url
  end

  test "GET /symptom_logs/:id.json returns log fields" do
    get symptom_log_url(@symptom_log), as: :json
    assert_response :ok
    json = response.parsed_body
    assert json.key?("id")
    assert json.key?("symptom_type")
    assert json.key?("severity")
    assert json.key?("triggers")
  end

  test "GET /symptom_logs/:id.json returns 404 for another user's entry" do
    get symptom_log_url(symptom_logs(:bob_coughing)), as: :json
    assert_response :not_found
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
    assert_select "h1", "Symptoms"
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

  test "create turbo stream response includes trend_bar replace" do
    post symptom_logs_url,
      params: { symptom_log: { symptom_type: "coughing", severity: "severe", recorded_at: Time.current } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "trend_bar", response.body
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

  # --- JSON ---

  test "GET /symptom_logs.json returns paginated envelope" do
    get symptom_logs_url, as: :json
    assert_response :ok
    json = response.parsed_body
    assert json.key?("symptom_logs"),    "missing symptom_logs key"
    assert json.key?("current_page"),   "missing current_page key"
    assert json.key?("total_pages"),    "missing total_pages key"
    assert json.key?("per_page"),       "missing per_page key"
    assert json.key?("applied_filters"), "missing applied_filters key"
    assert_kind_of Array, json["symptom_logs"]
  end

  test "GET /symptom_logs.json scopes to current user" do
    get symptom_logs_url, as: :json
    assert_response :ok
    ids = response.parsed_body["symptom_logs"].map { |l| l["id"] }
    assert_includes ids, @symptom_log.id
    assert_not_includes ids, symptom_logs(:bob_coughing).id
  end

  test "GET /symptom_logs.json returns expected fields including triggers" do
    get symptom_logs_url, as: :json
    assert_response :ok
    log = response.parsed_body["symptom_logs"].first
    assert log.key?("id")
    assert log.key?("symptom_type")
    assert log.key?("severity")
    assert log.key?("recorded_at")
    assert log.key?("notes")
    assert log.key?("triggers")
  end

  test "GET /symptom_logs.json with severity filter includes severity in applied_filters" do
    get symptom_logs_url(severity: "mild"), as: :json
    assert_response :ok
    assert_equal "mild", response.parsed_body["applied_filters"]["severity"]
  end

  test "POST /symptom_logs with valid JSON params creates log and returns 201" do
    assert_difference "SymptomLog.count", 1 do
      post symptom_logs_url,
        params: { symptom_log: { symptom_type: "coughing", severity: "mild", recorded_at: Time.current, triggers: [ "exercise", "cold_air" ] } },
        as: :json
    end
    assert_response :created
    json = response.parsed_body
    assert_equal "coughing", json["symptom_type"]
    assert_equal [ "exercise", "cold_air" ], json["triggers"]
    assert_equal @user, SymptomLog.last.user
  end

  test "POST /symptom_logs with invalid JSON params returns 422" do
    assert_no_difference "SymptomLog.count" do
      post symptom_logs_url,
        params: { symptom_log: { symptom_type: "", severity: "", recorded_at: "" } },
        as: :json
    end
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  test "PATCH /symptom_logs/:id with valid JSON params returns 200" do
    patch symptom_log_url(@symptom_log),
      params: { symptom_log: { severity: "severe" } },
      as: :json
    assert_response :ok
    assert_equal "severe", response.parsed_body["severity"]
    assert_equal "severe", @symptom_log.reload.severity
  end

  test "PATCH /symptom_logs/:id with invalid JSON params returns 422" do
    patch symptom_log_url(@symptom_log),
      params: { symptom_log: { symptom_type: "" } },
      as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  test "DELETE /symptom_logs/:id with JSON returns 204" do
    assert_difference "SymptomLog.count", -1 do
      delete symptom_log_url(@symptom_log), as: :json
    end
    assert_response :no_content
  end

  test "DELETE /symptom_logs/:id cannot delete another user's entry" do
    other_log = symptom_logs(:bob_coughing)
    assert_no_difference "SymptomLog.count" do
      delete symptom_log_url(other_log), as: :json
    end
    assert_response :not_found
  end

  # --- TIMELINE FILTERING ---

  test "index with preset 7 returns only entries from last 7 days" do
    sign_in_as users(:verified_user)
    get symptom_logs_url(preset: "7")
    assert_response :success
    assert_select ".timeline-row"  # at least one row visible
    # alice_coughing_old is 40 days ago — should not appear
    assert_select ".timeline-row", text: /coughing/i, count: 0
  end

  test "index with custom start_date filters correctly" do
    sign_in_as users(:verified_user)
    get symptom_logs_url(start_date: 10.days.ago.to_date.to_s, end_date: Date.current.to_s)
    assert_response :success
    assert_select ".timeline-row"
  end

  test "index scopes to current user — does not show other user entries" do
    sign_in_as users(:verified_user)
    get symptom_logs_url
    assert_response :success
    # bob_coughing must not appear in Alice's timeline
    assert_select ".timeline-row", text: /bob/i, count: 0
  end

  test "index with page param returns paginated subset" do
    sign_in_as users(:verified_user)
    get symptom_logs_url(page: 1)
    assert_response :success
  end

  test "index unauthenticated redirects" do
    sign_out
    get symptom_logs_url
    assert_redirected_to new_session_url
  end
end
