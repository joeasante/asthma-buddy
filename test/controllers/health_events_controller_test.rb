# frozen_string_literal: true

require "test_helper"

class HealthEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as(@user)
    @health_event = health_events(:alice_gp_appointment)
  end

  # --- SHOW ---

  test "show renders for owner" do
    get health_event_url(@health_event)
    assert_response :success
  end

  test "show returns 404 for another user's event" do
    get health_event_url(health_events(:bob_hospital))
    assert_response :not_found
  end

  test "show redirects unauthenticated user to sign in" do
    sign_out
    get health_event_url(@health_event)
    assert_redirected_to new_session_url
  end

  test "GET /medical-history/:id.json returns event fields" do
    get health_event_url(@health_event), as: :json
    assert_response :ok
    json = response.parsed_body
    assert json.key?("id")
    assert json.key?("event_type")
    assert json.key?("event_type_label")
    assert json.key?("ongoing")
    assert json.key?("recorded_at")
  end

  test "GET /medical-history/:id.json returns 404 for another user's event" do
    get health_event_url(health_events(:bob_hospital)), as: :json
    assert_response :not_found
  end

  # --- INDEX ---

  test "index renders for authenticated user" do
    get health_events_url
    assert_response :success
    assert_select "h1", "Medical History"
  end

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get health_events_url
    assert_redirected_to new_session_url
  end

  test "index shows only current user's events" do
    get health_events_url
    assert_response :success
    assert_select "##{dom_id(health_events(:alice_gp_appointment))}"
    assert_select "##{dom_id(health_events(:bob_hospital))}", count: 0
  end

  # --- NEW ---

  test "new renders for authenticated user" do
    get new_health_event_url
    assert_response :success
  end

  test "new redirects unauthenticated user to sign in" do
    sign_out
    get new_health_event_url
    assert_redirected_to new_session_url
  end

  # --- CREATE ---

  test "create with valid params saves event and redirects to index" do
    assert_difference "HealthEvent.count", 1 do
      post health_events_url, params: { health_event: { event_type: "illness", recorded_at: Time.current } }
    end
    assert_redirected_to health_events_path
  end

  test "create scopes new event to current user" do
    post health_events_url, params: { health_event: { event_type: "illness", recorded_at: Time.current } }
    assert_equal @user, HealthEvent.last.user
  end

  test "create with blank event_type renders new with unprocessable_entity" do
    assert_no_difference "HealthEvent.count" do
      post health_events_url, params: { health_event: { event_type: "", recorded_at: Time.current } }
    end
    assert_response :unprocessable_entity
  end

  test "create with blank recorded_at renders new with unprocessable_entity" do
    assert_no_difference "HealthEvent.count" do
      post health_events_url, params: { health_event: { event_type: "illness", recorded_at: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "create unauthenticated redirects to sign in" do
    sign_out
    post health_events_url, params: { health_event: { event_type: "illness", recorded_at: Time.current } }
    assert_redirected_to new_session_url
  end

  # --- EDIT ---

  test "edit renders for owner" do
    get edit_health_event_url(@health_event)
    assert_response :success
  end

  test "edit returns 404 for another user's event" do
    get edit_health_event_url(health_events(:bob_hospital))
    assert_response :not_found
  end

  test "edit redirects unauthenticated user to sign in" do
    sign_out
    get edit_health_event_url(@health_event)
    assert_redirected_to new_session_url
  end

  # --- UPDATE ---

  test "update with valid params updates record and redirects to index with notice" do
    patch health_event_url(@health_event), params: { health_event: { event_type: "illness", recorded_at: Time.current } }
    assert_redirected_to health_events_path
    assert_equal "Medical event updated.", flash[:notice]
  end

  test "update with blank event_type renders edit with unprocessable_entity" do
    patch health_event_url(@health_event), params: { health_event: { event_type: "" } }
    assert_response :unprocessable_entity
  end

  test "update returns 404 for another user's event" do
    patch health_event_url(health_events(:bob_hospital)),
      params: { health_event: { event_type: "illness", recorded_at: Time.current } }
    assert_response :not_found
  end

  # --- DESTROY ---

  test "destroy via turbo stream removes event and responds with turbo stream" do
    event = health_events(:alice_illness_ongoing)
    assert_difference "HealthEvent.count", -1 do
      delete health_event_url(event), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "destroy via html redirects to index" do
    event = health_events(:alice_illness_resolved)
    assert_difference "HealthEvent.count", -1 do
      delete health_event_url(event)
    end
    assert_redirected_to health_events_path
  end

  test "destroy returns 404 for another user's event" do
    assert_no_difference "HealthEvent.count" do
      delete health_event_url(health_events(:bob_hospital)),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :not_found
  end

  test "destroy unauthenticated redirects to sign in" do
    sign_out
    delete health_event_url(@health_event)
    assert_redirected_to new_session_url
  end
end
