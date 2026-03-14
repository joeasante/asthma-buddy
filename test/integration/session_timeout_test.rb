# frozen_string_literal: true

require "test_helper"

class SessionTimeoutTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
  end

  # Sign in via POST so SessionsController#create sets session[:last_seen_at].
  # Follows the redirect chain to the dashboard (POST -> root -> dashboard).
  def sign_in_via_post
    post session_path, params: { email_address: @user.email_address, password: "password123" }
    follow_redirect!  # root_url
    follow_redirect!  # dashboard_path
    assert_response :success
  end

  test "session idle for 61 minutes is expired and redirects to login" do
    sign_in_via_post

    travel 61.minutes do
      get dashboard_path
      assert_redirected_to new_session_path
      assert_equal "Your session expired due to inactivity. Please sign in again.", flash[:alert]
    end
  end

  test "session idle for 59 minutes passes through normally" do
    sign_in_via_post

    travel 59.minutes do
      get dashboard_path
      assert_response :success
    end
  end

  test "last_seen_at is updated on each authenticated request" do
    sign_in_via_post

    travel 30.minutes do
      get dashboard_path
      assert_response :success
      # Timestamp must have been refreshed to approximately the travelled-to now.
      assert_in_delta Time.current.to_i, session[:last_seen_at].to_time.to_i, 5
    end
  end

  test "session without last_seen_at set passes through (backward compatibility)" do
    # sign_in_as bypasses SessionsController#create, so last_seen_at is never set.
    sign_in_as(@user)
    get dashboard_path
    assert_response :success
  end
end
