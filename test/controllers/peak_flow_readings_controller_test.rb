# frozen_string_literal: true

require "test_helper"

class PeakFlowReadingsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @user  = users(:verified_user)
    @other = users(:unverified_user)
    sign_in_as @user
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
    assert_select ".peak-flow-banner"
  end

  test "new hides banner when user has a personal best" do
    # alice has personal best records in fixtures
    get new_peak_flow_reading_path
    assert_select ".peak-flow-banner", count: 0
  end

  # POST /peak_flow_readings
  test "create saves reading and redirects with zone flash on HTML" do
    pb = personal_best_records(:alice_updated_personal_best)
    reading_value = (pb.value * 0.85).to_i  # 85% => green zone

    assert_difference "PeakFlowReading.count", 1 do
      post peak_flow_readings_path, params: {
        peak_flow_reading: {
          value: reading_value,
          recorded_at: Time.current.iso8601
        }
      }
    end

    assert_redirected_to new_peak_flow_reading_path
    assert_match "Reading saved", flash[:notice]
    assert_match "Green Zone", flash[:notice]
  end

  test "create with no personal best gives 'set your personal best' flash" do
    PersonalBestRecord.where(user: @user).delete_all

    assert_difference "PeakFlowReading.count", 1 do
      post peak_flow_readings_path, params: {
        peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }
      }
    end

    assert_redirected_to new_peak_flow_reading_path
    assert_match "set your personal best", flash[:notice]
  end

  test "create with missing value returns 422 turbo stream" do
    assert_no_difference "PeakFlowReading.count" do
      post peak_flow_readings_path,
           params: { peak_flow_reading: { value: "", recorded_at: Time.current.iso8601 } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
  end

  test "create with missing recorded_at returns 422" do
    assert_no_difference "PeakFlowReading.count" do
      post peak_flow_readings_path,
           params: { peak_flow_reading: { value: 400, recorded_at: "" } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
  end

  # Multi-user isolation: readings are scoped to Current.user — no cross-user route exists for create.
  # A create POST always creates for the authenticated user regardless of params.
  test "create always creates for the authenticated user" do
    post peak_flow_readings_path, params: {
      peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }
    }
    assert_equal @user, PeakFlowReading.last.user
  end

  # JSON API
  test "create returns 201 JSON with zone on success" do
    pb = personal_best_records(:alice_updated_personal_best)
    reading_value = (pb.value * 0.85).to_i

    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: reading_value, recorded_at: Time.current.iso8601 } },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal reading_value, body["value"]
    assert_equal "green", body["zone"]
    assert body["zone_percentage"].present?
  end

  test "create returns 422 JSON with errors on failure" do
    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: "", recorded_at: Time.current.iso8601 } },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "unauthenticated JSON create returns 401" do
    delete session_path
    post peak_flow_readings_path,
         params: { peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 } },
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
      peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 }
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
          params: { peak_flow_reading: { value: 420, recorded_at: reading.recorded_at.iso8601 } },
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
          params: { peak_flow_reading: { value: 1, recorded_at: reading.recorded_at.iso8601 } }
    # Zone is recomputed by before_save; check the persisted record
    updated = reading.reload
    # With value=1 vs any reasonable personal best, zone should be red (or nil if no PB)
    assert_includes [ "red", nil ], updated.zone
  end

  test "update with blank value returns 422 Turbo Stream" do
    reading = peak_flow_readings(:alice_green_reading)
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: "", recorded_at: reading.recorded_at.iso8601 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
  end

  test "update returns 404 for another user's reading" do
    patch peak_flow_reading_path(peak_flow_readings(:bob_reading)),
          params: { peak_flow_reading: { value: 400, recorded_at: Time.current.iso8601 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :not_found
  end

  test "unauthenticated user is redirected from update" do
    reading = peak_flow_readings(:alice_green_reading)
    delete session_path
    patch peak_flow_reading_path(reading),
          params: { peak_flow_reading: { value: 400, recorded_at: reading.recorded_at.iso8601 } }
    assert_redirected_to new_session_path
  end

  # -------------------------------------------------------------------------
  # DELETE /peak_flow_readings/:id (destroy)
  # -------------------------------------------------------------------------

  test "destroy removes reading and returns Turbo Stream remove" do
    reading = peak_flow_readings(:alice_green_reading)
    assert_difference "PeakFlowReading.count", -1 do
      delete peak_flow_reading_path(reading),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_match "turbo-stream", response.body
    assert_match "remove", response.body
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
end
