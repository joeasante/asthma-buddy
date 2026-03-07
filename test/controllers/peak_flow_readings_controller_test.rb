# frozen_string_literal: true

require "test_helper"

class PeakFlowReadingsControllerTest < ActionDispatch::IntegrationTest
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
end
