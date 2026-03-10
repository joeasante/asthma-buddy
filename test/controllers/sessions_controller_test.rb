# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
  end

  test "GET /session/new returns 200 with login form" do
    get new_session_path
    assert_response :success
    assert_select "form"
    assert_select "input[type=email]"
    assert_select "input[type=password]"
  end

  test "POST /session with valid credentials creates session and redirects" do
    assert_difference "Session.count", 1 do
      post session_path, params: { email_address: @user.email_address, password: "password123" }
    end
    assert_redirected_to root_path
  end

  test "POST /session with wrong password does not create session" do
    assert_no_difference "Session.count" do
      post session_path, params: { email_address: @user.email_address, password: "wrongpassword" }
    end
    assert_redirected_to new_session_path
  end

  test "POST /session with non-existent email does not create session" do
    assert_no_difference "Session.count" do
      post session_path, params: { email_address: "nobody@example.com", password: "password123" }
    end
    assert_redirected_to new_session_path
  end

  test "DELETE /session destroys session and redirects" do
    sign_in_as(@user)

    assert_difference "Session.count", -1 do
      delete session_path
    end
    assert_redirected_to new_session_path
  end

  test "POST /session with unverified user does not create session" do
    unverified = users(:unverified_user)

    assert_no_difference "Session.count" do
      post session_path, params: { email_address: unverified.email_address, password: "password123" }
    end

    assert_redirected_to new_session_path
    assert_match "verify your email", flash[:alert]
  end

  test "POST /session sets a persistent cookie with future expiry" do
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    assert_response :redirect

    cookie = cookies["session_id"]
    assert_not_nil cookie, "session_id cookie should be set"
  end

  test "unauthenticated DELETE to session (protected destroy) redirects to login" do
    # SessionsController#destroy is not in allow_unauthenticated_access
    delete session_path
    assert_redirected_to new_session_path
  end

  # --- JSON ---

  test "POST /session with valid credentials returns 201 JSON with message" do
    assert_difference "Session.count", 1 do
      post session_path,
        params: { email_address: @user.email_address, password: "password123" },
        as: :json
    end
    assert_response :created
    json = response.parsed_body
    assert_equal "Signed in.", json["message"]
    assert_nil json["session_id"], "must not expose internal DB id"
  end

  test "POST /session with wrong password returns 401 JSON" do
    assert_no_difference "Session.count" do
      post session_path,
        params: { email_address: @user.email_address, password: "wrongpassword" },
        as: :json
    end
    assert_response :unauthorized
    assert_equal "Invalid email address or password", response.parsed_body["error"]
  end

  test "POST /session with unverified user returns 403 JSON with verification message" do
    unverified = users(:unverified_user)
    assert_no_difference "Session.count" do
      post session_path,
        params: { email_address: unverified.email_address, password: "password123" },
        as: :json
    end
    assert_response :forbidden
    assert_match "verified", response.parsed_body["error"]
  end

  test "DELETE /session with JSON returns 204" do
    sign_in_as(@user)
    delete session_path, as: :json
    assert_response :no_content
  end

  test "unauthenticated JSON request to protected resource returns 401" do
    get symptom_logs_path, as: :json
    assert_response :unauthorized
    assert_equal "Authentication required", response.parsed_body["error"]
  end
end
