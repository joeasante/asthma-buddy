# frozen_string_literal: true

require "test_helper"
require_relative "base_api_test_helper"

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    setup_api_user
  end

  # --- Authentication ---

  test "returns 401 when no authorization header" do
    get api_v1_account_url
    assert_unauthorized
  end

  test "returns 401 with invalid token" do
    get api_v1_account_url, headers: api_headers("invalid_token")
    assert_unauthorized
  end

  test "returns 401 with revoked key" do
    @api_user.revoke_api_key!
    get api_v1_account_url, headers: api_headers(@api_token)
    assert_unauthorized
  end

  # --- Account data ---

  test "returns account data for premium user" do
    get api_v1_account_url, headers: api_headers(@api_token)
    assert_response :ok

    data = parsed_response["data"]
    assert_equal @api_user.id, data["id"]
    assert_equal @api_user.email_address, data["email"]
    assert_equal "premium", data["plan"]
    assert_equal "active", data["subscription_status"]
    assert_not data["on_trial"]
    assert_not_nil data["features"]
  end

  test "returns feature capabilities in response" do
    get api_v1_account_url, headers: api_headers(@api_token)
    assert_response :ok

    features = parsed_response["data"]["features"]
    assert_nil features["symptom_log_history_days"]
    assert_nil features["peak_flow_history_days"]
  end

  test "returns free plan features for free user" do
    free_user = users(:admin_user)
    free_user.update!(role: :member)
    token = free_user.generate_api_key!

    get api_v1_account_url, headers: api_headers(token)
    assert_response :ok

    data = parsed_response["data"]
    assert_equal "free", data["plan"]
    assert_equal 30, data["features"]["symptom_log_history_days"]
    assert_equal 30, data["features"]["peak_flow_history_days"]
  end
end
