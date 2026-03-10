# frozen_string_literal: true

require "test_helper"

class Settings::DoseLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @other_user = users(:unverified_user)
    sign_in_as(@user)
    @medication = medications(:alice_reliever)
    @other_medication = medications(:bob_reliever)
    @dose_log = dose_logs(:alice_reliever_dose_1)
    @other_dose_log = dose_logs(:bob_reliever_dose_1)
  end

  # --- CREATE ---

  test "create saves a valid dose log and responds with turbo stream" do
    assert_difference "DoseLog.count", 1 do
      post settings_medication_dose_logs_url(@medication),
        params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "create scopes new dose log to current user" do
    post settings_medication_dose_logs_url(@medication),
      params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } }
    assert_equal @user, DoseLog.last.user
  end

  test "create scopes new dose log to the target medication" do
    post settings_medication_dose_logs_url(@medication),
      params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } }
    assert_equal @medication, DoseLog.last.medication
  end

  test "create with invalid params (zero puffs) renders unprocessable_entity" do
    assert_no_difference "DoseLog.count" do
      post settings_medication_dose_logs_url(@medication),
        params: { dose_log: { puffs: 0, recorded_at: Time.current.to_s } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  test "create with missing puffs renders unprocessable_entity" do
    assert_no_difference "DoseLog.count" do
      post settings_medication_dose_logs_url(@medication),
        params: { dose_log: { puffs: "", recorded_at: Time.current.to_s } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  test "create returns 404 when medication belongs to another user" do
    assert_no_difference "DoseLog.count" do
      post settings_medication_dose_logs_url(@other_medication),
        params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } }
    end
    assert_response :not_found
  end

  test "create redirects unauthenticated user to sign in" do
    sign_out
    post settings_medication_dose_logs_url(@medication),
      params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } }
    assert_redirected_to new_session_url
  end

  # --- DESTROY ---

  test "destroy removes the dose log and responds with turbo stream" do
    assert_difference "DoseLog.count", -1 do
      delete settings_medication_dose_log_url(@medication, @dose_log),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "destroy returns 404 when medication belongs to another user" do
    assert_no_difference "DoseLog.count" do
      delete settings_medication_dose_log_url(@other_medication, @other_dose_log)
    end
    assert_response :not_found
  end

  test "destroy returns 404 when dose log belongs to a different medication" do
    # alice_reliever_dose_1 belongs to alice_reliever; route uses bob_reliever as medication_id
    # set_dose_log calls @medication.dose_logs.find — raises RecordNotFound because
    # alice's dose log is not in bob's medication's dose_logs scope.
    assert_no_difference "DoseLog.count" do
      delete settings_medication_dose_log_url(@medication, @other_dose_log)
    end
    assert_response :not_found
  end

  test "destroy redirects unauthenticated user to sign in" do
    sign_out
    delete settings_medication_dose_log_url(@medication, @dose_log)
    assert_redirected_to new_session_url
  end

  # --- JSON: CREATE ---

  test "POST /settings/medications/:medication_id/dose_logs.json returns 201 with dose_log JSON" do
    assert_difference "DoseLog.count", 1 do
      post settings_medication_dose_logs_url(@medication, format: :json),
        params: { dose_log: { puffs: 2, recorded_at: Time.current.to_s } }
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert_equal @medication.id, body["medication_id"]
    assert_equal 2, body["puffs"]
    assert body.key?("id")
    assert body.key?("recorded_at")
    assert body.key?("created_at")
  end

  test "POST /settings/medications/:medication_id/dose_logs.json with invalid params returns 422" do
    assert_no_difference "DoseLog.count" do
      post settings_medication_dose_logs_url(@medication, format: :json),
        params: { dose_log: { puffs: 0, recorded_at: Time.current.to_s } }
    end
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body.key?("errors")
  end

  # --- JSON: DESTROY ---

  test "DELETE /settings/medications/:medication_id/dose_logs/:id.json returns 204 no content" do
    assert_difference "DoseLog.count", -1 do
      delete settings_medication_dose_log_url(@medication, @dose_log, format: :json)
    end
    assert_response :no_content
  end
end
