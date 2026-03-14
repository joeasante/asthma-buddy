# frozen_string_literal: true

require "test_helper"
require_relative "base_api_test_helper"

class Api::V1::SymptomLogsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    setup_api_user
    setup_other_user
  end

  # --- Authentication ---

  test "returns 401 when no authorization header" do
    get api_v1_symptom_logs_url
    assert_unauthorized
  end

  test "returns 401 with invalid token" do
    get api_v1_symptom_logs_url, headers: api_headers("invalid_token")
    assert_unauthorized
  end

  test "returns 401 with revoked key" do
    @api_user.revoke_api_key!
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    assert_unauthorized
  end

  test "returns 200 with valid token" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    assert_response :ok
  end

  # --- Data scoping ---

  test "returns only current user records" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    assert_response :ok
    data = parsed_response["data"]
    # verified_user has 4 symptom logs, bob has 1
    assert_equal @api_user.symptom_logs.count, data.size
    data.each do |log|
      assert_includes @api_user.symptom_logs.pluck(:id), log["id"]
    end
  end

  test "returns empty array when user has no records" do
    # new_user has no symptom logs
    new_user = users(:new_user)
    token = new_user.generate_api_key!
    get api_v1_symptom_logs_url, headers: api_headers(token)
    assert_response :ok
    assert_equal [], parsed_response["data"]
    assert_equal 0, parsed_response["meta"]["total"]
  end

  # --- Pagination ---

  test "default pagination returns page 1 with per_page 25" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    meta = parsed_response["meta"]
    assert_equal 1, meta["page"]
    assert_equal 25, meta["per_page"]
  end

  test "custom page and per_page params work" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { page: 1, per_page: 2 }
    meta = parsed_response["meta"]
    assert_equal 1, meta["page"]
    assert_equal 2, meta["per_page"]
    assert_equal 2, parsed_response["data"].size
  end

  test "per_page is capped at 100" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { per_page: 200 }
    meta = parsed_response["meta"]
    assert_equal 100, meta["per_page"]
  end

  test "page beyond range returns empty data" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { page: 999 }
    assert_response :ok
    assert_equal [], parsed_response["data"]
    assert parsed_response["meta"]["total"] > 0
  end

  test "meta includes page per_page and total" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    meta = parsed_response["meta"]
    assert meta.key?("page")
    assert meta.key?("per_page")
    assert meta.key?("total")
  end

  # --- Filtering ---

  test "date_from filters records on or after that date" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { date_from: 2.days.ago.to_date.to_s }
    data = parsed_response["data"]
    data.each do |log|
      assert Time.parse(log["recorded_at"]) >= 2.days.ago.beginning_of_day
    end
  end

  test "date_to filters records on or before that date" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { date_to: 10.days.ago.to_date.to_s }
    data = parsed_response["data"]
    data.each do |log|
      assert Time.parse(log["recorded_at"]) <= 10.days.ago.end_of_day
    end
  end

  test "date range filters correctly" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { date_from: 6.days.ago.to_date.to_s, date_to: 2.days.ago.to_date.to_s }
    data = parsed_response["data"]
    data.each do |log|
      recorded = Time.parse(log["recorded_at"])
      assert recorded >= 6.days.ago.beginning_of_day
      assert recorded <= 2.days.ago.end_of_day
    end
  end

  test "invalid date format returns 400" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token),
      params: { date_from: "not-a-date" }
    assert_response :bad_request
    assert_equal 400, parsed_response["error"]["status"]
  end

  # --- Response format ---

  test "response has data array and meta object" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    assert parsed_response.key?("data")
    assert parsed_response["data"].is_a?(Array)
    assert parsed_response.key?("meta")
    assert parsed_response["meta"].is_a?(Hash)
  end

  test "each record has expected fields" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    record = parsed_response["data"].first
    assert record.key?("id")
    assert record.key?("symptom_type")
    assert record.key?("severity")
    assert record.key?("triggers")
    assert record.key?("recorded_at")
    assert record.key?("created_at")
  end

  test "records ordered by date descending" do
    get api_v1_symptom_logs_url, headers: api_headers(@api_token)
    dates = parsed_response["data"].map { |r| Time.parse(r["recorded_at"]) }
    assert_equal dates.sort.reverse, dates
  end
end
