# frozen_string_literal: true

module ApiTestHelper
  def api_headers(token)
    { "Authorization" => "Bearer #{token}", "Accept" => "application/json" }
  end

  def setup_api_user
    @api_user = users(:verified_user)
    @api_token = @api_user.generate_api_key!
  end

  def setup_other_user
    @other_user = users(:unverified_user)
  end

  def parsed_response
    JSON.parse(response.body)
  end

  def assert_unauthorized
    assert_response :unauthorized
    error = parsed_response["error"]
    assert_equal 401, error["status"]
    assert error["message"].present?
  end
end
