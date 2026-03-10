# frozen_string_literal: true

require "test_helper"

class CookieNoticesControllerTest < ActionDispatch::IntegrationTest
  test "POST /cookie-notice/dismiss returns 204 and sets session flag" do
    post cookie_notice_dismiss_path
    assert_response :no_content
    assert session[:cookie_notice_shown]
  end

  test "POST /cookie-notice/dismiss is accessible without authentication" do
    post cookie_notice_dismiss_path
    assert_response :no_content
  end

  test "cookie notice does not render after dismissal" do
    post cookie_notice_dismiss_path
    # Session flag is set — subsequent requests should not render the banner
    get root_path
    assert_response :success
    assert_select ".cookie-notice", count: 0
  end
end
