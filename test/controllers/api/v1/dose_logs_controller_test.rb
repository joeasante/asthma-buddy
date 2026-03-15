# frozen_string_literal: true

require "test_helper"
require_relative "base_api_test_helper"

class Api::V1::DoseLogsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    setup_api_user
    setup_other_user
  end

  # --- Authentication (spot-check) ---

  test "returns 401 without auth" do
    get api_v1_dose_logs_url
    assert_unauthorized
  end

  test "returns 200 with valid token" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token)
    assert_response :ok
  end

  # --- Data scoping ---

  test "returns only current user records" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token)
    data = parsed_response["data"]
    assert_equal @api_user.dose_logs.count, data.size
    user_ids = @api_user.dose_logs.pluck(:id)
    data.each { |r| assert_includes user_ids, r["id"] }
  end

  test "returns empty array when user has no records" do
    new_user = users(:new_user)
    token = new_user.generate_api_key!
    make_premium(new_user)
    get api_v1_dose_logs_url, headers: api_headers(token)
    assert_response :ok
    assert_equal [], parsed_response["data"]
  end

  # --- Filtering ---

  test "date_from filters records" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token),
      params: { date_from: 1.day.ago.to_date.to_s }
    data = parsed_response["data"]
    data.each do |r|
      assert Time.parse(r["recorded_at"]) >= 1.day.ago.beginning_of_day
    end
  end

  test "date range filters correctly" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token),
      params: { date_from: 3.days.ago.to_date.to_s, date_to: 1.day.ago.to_date.to_s }
    data = parsed_response["data"]
    data.each do |r|
      recorded = Time.parse(r["recorded_at"])
      assert recorded >= 3.days.ago.beginning_of_day
      assert recorded <= 1.day.ago.end_of_day
    end
  end

  test "invalid date returns 400" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token),
      params: { date_to: "xyz" }
    assert_response :bad_request
  end

  # --- Response format ---

  test "response has data and meta" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token)
    assert parsed_response.key?("data")
    assert parsed_response.key?("meta")
  end

  test "each record has expected fields" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token)
    record = parsed_response["data"].first
    %w[id medication_id medication_name puffs recorded_at created_at].each do |field|
      assert record.key?(field), "Missing field: #{field}"
    end
  end

  test "records ordered by date descending" do
    get api_v1_dose_logs_url, headers: api_headers(@api_token)
    dates = parsed_response["data"].map { |r| Time.parse(r["recorded_at"]) }
    assert_equal dates.sort.reverse, dates
  end
end
