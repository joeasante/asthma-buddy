# frozen_string_literal: true

require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    # Re-enable rack-attack for this test class and reset its counters.
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  teardown do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  test "6th login POST from same IP within 20 seconds is throttled with 429" do
    5.times do
      post session_path, params: { email_address: "x@example.com", password: "wrong" },
        headers: { "REMOTE_ADDR" => "1.2.3.4" }
    end
    post session_path, params: { email_address: "x@example.com", password: "wrong" },
      headers: { "REMOTE_ADDR" => "1.2.3.4" }
    assert_response 429
  end

  test "different IPs are not affected by each other's login throttle" do
    5.times do
      post session_path, params: { email_address: "x@example.com", password: "wrong" },
        headers: { "REMOTE_ADDR" => "1.2.3.4" }
    end
    post session_path, params: { email_address: "x@example.com", password: "wrong" },
      headers: { "REMOTE_ADDR" => "9.9.9.9" }
    assert_response :redirect  # redirected to login with alert — not 429
  end

  test "4th signup POST from same IP within one hour is throttled with 429" do
    3.times do
      post registration_path,
        params: { user: { email_address: "a@example.com", password: "pass1234", password_confirmation: "pass1234" } },
        headers: { "REMOTE_ADDR" => "2.3.4.5" }
    end
    post registration_path,
      params: { user: { email_address: "b@example.com", password: "pass1234", password_confirmation: "pass1234" } },
      headers: { "REMOTE_ADDR" => "2.3.4.5" }
    assert_response 429
  end
end
