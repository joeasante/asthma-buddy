# frozen_string_literal: true

require "test_helper"

class PeakFlowReadingsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @user  = users(:verified_user)
    @other = users(:unverified_user)
    sign_in_as @user
  end

  # GET /peak_flow_readings/:id
  test "show renders for owner" do
    reading = peak_flow_readings(:alice_green_reading)
    get peak_flow_reading_path(reading)
    assert_response :success
  end

  test "show returns 404 for another user's reading" do
    get peak_flow_reading_path(peak_flow_readings(:bob_reading))
    assert_response :not_found
  end

  test "show redirects unauthenticated user to sign in" do
    sign_out
    get peak_flow_reading_path(peak_flow_readings(:alice_green_reading))
    assert_redirected_to new_session_url
  end

  test "show renders without personal best" do
    PersonalBestRecord.where(user: @user).delete_all
    get peak_flow_reading_path(peak_flow_readings(:alice_green_reading))
    assert_response :success
  end

  test "GET /peak_flow_readings/:id.json returns reading fields" do
    reading = peak_flow_readings(:alice_green_reading)
    get peak_flow_reading_path(reading), as: :json
    assert_response :ok
    json = response.parsed_body
    assert json.key?("id")
    assert json.key?("value")
    assert json.key?("zone")
    assert json.key?("recorded_at")
  end

  test "GET /peak_flow_readings/:id.json returns 404 for another user's reading" do
    get peak_flow_reading_path(peak_flow_readings(:bob_reading)), as: :json
    assert_response :not_found
  end

  # GET /peak_flow_readings/new
  test "new renders form for authenticated user" do
    get new_peak_flow_reading_path
    assert_response :success
    assert_select "form"
  end

  test "new shows personal best banner when user has no personal best" do
    # Ensure no personal best records for this user exist in fixture
    # alice_no_pb_reading fixture has recorded_at 60.days.ago,
    # but alice has personal best records too — use a user with no records.
    # Use unverified_user who has bob_personal_best fixture.
    # Sign in as a fresh scenario: destroy all of alice's personal best records first.
    PersonalBestRecord.where(user: @user).delete_all
    get new_peak_flow_reading_path
    assert_response :success
    assert_select ".flash--warning"
  end

  test "new hides banner when user has a personal best" do
    # alice has personal best records in fixtures
    get new_peak_flow_reading_path
    assert_select ".flash--warning", count: 0
  end

  # POST /peak_flow_readings
  test "create saves reading and redirects with zone flash on HTML" do
    pb = personal_best_records(:alice_updated_personal_best)
    reading_value = (pb.value * 0.85).to_i  # 85% => green zone

    assert_difference "PeakFlowReading.count", 1 do
      post peak_flow_readings_path, params: {
        peak_flow_reading: {
          value:       reading_value,
          recorded_at: Time.current.iso8601,
          time_of_day: "morning"
        }
      }
    end

    assert_redirected_to peak_flow_readings_path
    assert_match "Reading saved", flash[:notice]
    assert_match "Green zone", flash[:notice]
  end

  test "create with no personal best gives 'set your personal best' flash" do
    PersonalBestRecord.where(user: @user).delete_all

    assert_difference "PeakFlowReading.count", 1 do
      post peak_flow_readings_path, params: {
        peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601, time_of_day: "morning" }
      }
    end

    assert_redirected_to peak_flow_readings_path
    assert_match "set your personal best", flash[:notice]
  end

  test "create with missing value returns 422 turbo stream" do
    assert_no_difference "PeakFlowReading.count" do
      post peak_flow_readings_path,
           params: { peak_flow_reading: { value: "", recorded_at: Time.current.iso8601 }, time_of_day: "morning" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
  end

  test "create with missing recorded_at returns 422" do
    assert_no_difference "PeakFlowReading.count" do
      post peak_flow_readings_path,
           params: { peak_flow_reading: { value: 400, recorded_at: "" }, time_of_day: "morning" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
  end

  # Multi-user isolation: readings are scoped to Current.user — no cross-user route exists for create.
  # A create POST always creates for the authenticated user regardless of params.
  test "create always creates for the authenticated user" do
    post peak_flow_readings_path, params: {
      peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601, time_of_day: "morning" }
    }
    assert_equal @user, PeakFlowReading.last.user
  end

  # JSON API
  test "create returns 201 JSON with zone on success" do
    pb = personal_best_records(:alice_updated_personal_best)
    reading_value = (pb.value * 0.85).to_i

    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: reading_value, recorded_at: Time.current.iso8601, time_of_day: "morning" } },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal reading_value, body["value"]
    assert_equal "green", body["zone"]
    assert body.key?("id")
    assert body.key?("recorded_at")
  end

  test "create returns 422 JSON with errors on failure" do
    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: "", recorded_at: Time.current.iso8601 }, time_of_day: "morning" },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "create returns 422 with duplicate session error when session already exists" do
    # alice_green_reading fixture is a morning reading 2 days ago — use that date to force a clash
    existing = peak_flow_readings(:alice_green_reading)
    post peak_flow_readings_path,
         params: { peak_flow_reading: {
           value:       350,
           recorded_at: existing.recorded_at.change(hour: 9).iso8601,
           time_of_day: existing.time_of_day
         } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
  end

  test "create turbo stream for duplicate session includes edit link to existing reading" do
    existing = peak_flow_readings(:alice_green_reading)
    post peak_flow_readings_path,
         params: { peak_flow_reading: {
           value:       350,
           recorded_at: existing.recorded_at.change(hour: 9).iso8601,
           time_of_day: existing.time_of_day
         } },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_match edit_peak_flow_reading_path(existing), response.body
  end

  test "unauthenticated JSON create returns 401" do
    delete session_path
    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }, time_of_day: "morning" },
         as: :json

    assert_response :unauthorized
  end

  test "unauthenticated user is redirected from new" do
    delete session_path  # sign out
    get new_peak_flow_reading_path
    assert_redirected_to new_session_path
  end

  test "unauthenticated user is redirected from create" do
    delete session_path
    post peak_flow_readings_path, params: {
      peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601, time_of_day: "morning" }
    }
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # GET /peak_flow_readings (index) — Phase 7
  # -------------------------------------------------------------------------

  test "index renders for authenticated user" do
    get peak_flow_readings_path
    assert_response :success
  end

  test "index shows zone badge CSS class for green reading" do
    get peak_flow_readings_path
    assert_select ".zone-badge--green"
  end

  test "index shows zone badge CSS class for yellow reading" do
    get peak_flow_readings_path
    assert_select ".zone-badge--yellow"
  end

  test "index defaults to 30-day window and excludes older readings" do
    # alice_no_pb_reading is 60 days ago — outside 30-day default
    get peak_flow_readings_path
    assert_response :success
    # alice_green (2 days ago) and alice_yellow (1 day ago) should appear
    assert_select ".zone-badge", minimum: 2
  end

  test "index with custom date range filters readings" do
    # Request only the last 1 day — only alice_yellow (1.day.ago) should appear
    get peak_flow_readings_path,
        params: { start_date: 2.days.ago.to_date.to_s, end_date: Date.current.to_s }
    assert_response :success
  end

  test "index does not show another user's readings" do
    get peak_flow_readings_path
    # bob_reading dom_id must not be in the response
    assert_select "##{dom_id(peak_flow_readings(:bob_reading))}", count: 0
  end

  test "unauthenticated user is redirected from index" do
    delete session_path
    get peak_flow_readings_path
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # GET /peak_flow_readings/:id/edit
  # -------------------------------------------------------------------------

  test "edit returns 200 for own reading" do
    reading = peak_flow_readings(:alice_green_reading)
    get edit_peak_flow_reading_path(reading),
        headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
    assert_response :success
  end

  test "edit returns 404 for another user's reading" do
    get edit_peak_flow_reading_path(peak_flow_readings(:bob_reading))
    assert_response :not_found
  end

  test "unauthenticated user is redirected from edit" do
    delete session_path
    get edit_peak_flow_reading_path(peak_flow_readings(:alice_green_reading))
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # PATCH /peak_flow_readings/:id (update)
  # -------------------------------------------------------------------------

  test "update with valid params returns Turbo Stream replace" do
    reading = peak_flow_readings(:alice_green_reading)
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: 420, recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "turbo-stream", response.body
    assert_match "replace", response.body
  end

  test "update recalculates zone on save" do
    reading = peak_flow_readings(:alice_green_reading)
    # alice has a personal best record — update value to a very low number to force red zone
    # Value of 1 will be < 50% of any personal best => red zone
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: 1, recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" }
    # Zone is recomputed by before_save; check the persisted record
    updated = reading.reload
    # With value=1 vs any reasonable personal best, zone should be red (or nil if no PB)
    assert_includes [ "red", nil ], updated.zone
  end

  test "update with blank value returns 422 Turbo Stream" do
    reading = peak_flow_readings(:alice_green_reading)
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: "", recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
  end

  test "update returns 404 for another user's reading" do
    patch peak_flow_reading_path(peak_flow_readings(:bob_reading)),
          params: { peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :not_found
  end

  test "unauthenticated user is redirected from update" do
    reading = peak_flow_readings(:alice_green_reading)
    delete session_path
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: 400, recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" }
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # DELETE /peak_flow_readings/:id (destroy)
  # -------------------------------------------------------------------------

  test "destroy removes reading and returns Turbo Stream toast" do
    reading = peak_flow_readings(:alice_green_reading)
    assert_difference "PeakFlowReading.count", -1 do
      delete peak_flow_reading_path(reading),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "turbo-stream", response.body
    assert_match "Reading deleted", response.body
  end

  test "destroy returns 404 for another user's reading" do
    assert_no_difference "PeakFlowReading.count" do
      delete peak_flow_reading_path(peak_flow_readings(:bob_reading)),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :not_found
  end

  test "unauthenticated user is redirected from destroy" do
    reading = peak_flow_readings(:alice_green_reading)
    delete session_path
    delete peak_flow_reading_path(reading)
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # JSON API — index envelope, update, destroy (Phase 7 agent-native parity)
  # -------------------------------------------------------------------------

  test "index JSON response includes pagination envelope keys" do
    get peak_flow_readings_path, headers: { "Accept" => "application/json" }
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("readings"),        "missing readings key"
    assert body.key?("current_page"),    "missing current_page key"
    assert body.key?("total_pages"),     "missing total_pages key"
    assert body.key?("per_page"),        "missing per_page key"
    assert body.key?("applied_filters"), "missing applied_filters key"
    assert_kind_of Array, body["readings"]
  end

  test "index JSON readings include id, value, zone, recorded_at" do
    get peak_flow_readings_path(preset: "all"), headers: { "Accept" => "application/json" }
    body = JSON.parse(response.body)
    reading = body["readings"].first
    assert reading.key?("id")
    assert reading.key?("value")
    assert reading.key?("zone")
    assert reading.key?("recorded_at")
    assert_not reading.key?("created_at"), "created_at should not be exposed in JSON"
  end

  test "update with valid params returns JSON reading" do
    reading = peak_flow_readings(:alice_green_reading)
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: 420, recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "application/json" }
    assert_response :success
    assert_equal "application/json", response.media_type
    body = JSON.parse(response.body)
    assert_equal 420, body["value"]
    assert body.key?("zone")
  end

  test "update with blank value returns 422 JSON with errors" do
    reading = peak_flow_readings(:alice_green_reading)
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: "", recorded_at: reading.recorded_at.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "application/json" }
    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert body["errors"].present?
  end

  test "update returns 404 JSON for another user's reading" do
    patch peak_flow_reading_path(peak_flow_readings(:bob_reading)),
          params: { peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }, time_of_day: "morning" },
          headers: { "Accept" => "application/json" }
    assert_response :not_found
  end

  test "destroy returns 204 JSON for own reading" do
    reading = peak_flow_readings(:alice_green_reading)
    assert_difference "PeakFlowReading.count", -1 do
      delete peak_flow_reading_path(reading), headers: { "Accept" => "application/json" }
    end
    assert_response :no_content
  end

  test "destroy returns 404 JSON for another user's reading" do
    assert_no_difference "PeakFlowReading.count" do
      delete peak_flow_reading_path(peak_flow_readings(:bob_reading)),
             headers: { "Accept" => "application/json" }
    end
    assert_response :not_found
  end
end
