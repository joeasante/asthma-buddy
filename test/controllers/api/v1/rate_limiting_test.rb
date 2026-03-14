# frozen_string_literal: true

require "test_helper"

class Api::V1::RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.reset!

    @user = users(:verified_user)
    @api_key = @user.generate_api_key!
  end

  teardown do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  test "API requests within limit succeed" do
    3.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    # Requests should not be throttled (all under limit of 60)
    # Last response should NOT be 429
    assert_not_equal 429, response.status
  end

  test "API requests exceeding limit get 429" do
    61.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    assert_response 429
  end

  test "429 response includes Retry-After header" do
    61.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    assert_response 429
    assert response.headers["Retry-After"].present?, "Expected Retry-After header"
    assert response.headers["Retry-After"].to_i > 0, "Retry-After should be a positive integer"
  end

  test "429 response body is consistent JSON error format" do
    61.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    assert_response 429

    body = JSON.parse(response.body)
    assert_equal 429, body.dig("error", "status")
    assert_equal "Rate limit exceeded. Try again later.", body.dig("error", "message")
    assert_nil body.dig("error", "details")
  end

  test "web requests are not affected by API rate limit" do
    # Exhaust API rate limit
    61.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    assert_response 429

    # Web request should still work
    sign_in_as @user
    get settings_path
    assert_response :success
  end

  test "different API keys have independent limits" do
    user_b = users(:mfa_user)
    api_key_b = user_b.generate_api_key!

    # Exhaust User A's rate limit
    61.times do
      get "/api/v1/symptom_logs", headers: auth_headers(@api_key)
    end
    assert_response 429

    # User B should still be able to make requests
    get "/api/v1/symptom_logs", headers: auth_headers(api_key_b)
    assert_not_equal 429, response.status
  end

  private

  def auth_headers(token)
    { "Authorization" => "Bearer #{token}" }
  end
end
