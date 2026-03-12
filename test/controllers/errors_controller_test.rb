# frozen_string_literal: true

require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  test "GET /404 returns 404 status" do
    get "/404"
    assert_response :not_found
  end

  test "GET /404 renders not found content" do
    get "/404"
    assert_select "h1", text: /page not found/i
    assert_select ".btn-primary"
  end

  test "GET /500 returns 500 status" do
    get "/500"
    assert_response :internal_server_error
  end

  test "GET /500 renders error content" do
    get "/500"
    assert_select "h1", text: /something went wrong/i
    assert_select ".btn-primary"
  end

  test "GET /404 accessible without authentication" do
    get "/404"
    assert_response :not_found
    # Should not redirect to login
    assert_not_equal new_session_url, response.location
  end

  test "GET /500 accessible without authentication" do
    get "/500"
    assert_response :internal_server_error
    assert_not_equal new_session_url, response.location
  end

  test "GET /404 home link goes to root path" do
    get "/404"
    assert_select ".btn-primary[href='#{root_path}']"
  end

  test "GET /500 home link goes to root path" do
    get "/500"
    assert_select ".btn-primary[href='#{root_path}']"
  end

  test "GET /500 does not render cookie notice" do
    get "/500"
    assert_select ".cookie-notice", count: 0
  end

  test "GET /404 does not render cookie notice" do
    get "/404"
    assert_select ".cookie-notice", count: 0
  end
end
