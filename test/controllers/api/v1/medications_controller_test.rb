# frozen_string_literal: true

require "test_helper"
require_relative "base_api_test_helper"

class Api::V1::MedicationsControllerTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  setup do
    setup_api_user
    setup_other_user
  end

  # --- Authentication (spot-check) ---

  test "returns 401 without auth" do
    get api_v1_medications_url
    assert_unauthorized
  end

  test "returns 200 with valid token" do
    get api_v1_medications_url, headers: api_headers(@api_token)
    assert_response :ok
  end

  # --- Data scoping ---

  test "returns only current user records" do
    get api_v1_medications_url, headers: api_headers(@api_token)
    data = parsed_response["data"]
    assert_equal @api_user.medications.count, data.size
    user_ids = @api_user.medications.pluck(:id)
    data.each { |r| assert_includes user_ids, r["id"] }
  end

  test "returns empty array when user has no records" do
    new_user = users(:new_user)
    token = new_user.generate_api_key!
    make_premium(new_user)
    get api_v1_medications_url, headers: api_headers(token)
    assert_response :ok
    assert_equal [], parsed_response["data"]
  end

  # --- Pagination (spot-check) ---

  test "custom per_page works" do
    get api_v1_medications_url, headers: api_headers(@api_token),
      params: { per_page: 2 }
    meta = parsed_response["meta"]
    assert_equal 2, meta["per_page"]
    assert_equal 2, parsed_response["data"].size
  end

  test "per_page capped at 100" do
    get api_v1_medications_url, headers: api_headers(@api_token),
      params: { per_page: 500 }
    assert_equal 100, parsed_response["meta"]["per_page"]
  end

  # --- Response format ---

  test "response has data and meta" do
    get api_v1_medications_url, headers: api_headers(@api_token)
    assert parsed_response.key?("data")
    assert parsed_response.key?("meta")
  end

  test "each record has expected fields" do
    get api_v1_medications_url, headers: api_headers(@api_token)
    record = parsed_response["data"].first
    %w[id name medication_type dose_unit standard_dose_puffs doses_per_day starting_dose_count remaining_doses created_at].each do |field|
      assert record.key?(field), "Missing field: #{field}"
    end
  end

  test "records ordered by created_at descending" do
    get api_v1_medications_url, headers: api_headers(@api_token)
    dates = parsed_response["data"].map { |r| Time.parse(r["created_at"]) }
    assert_equal dates.sort.reverse, dates
  end
end
