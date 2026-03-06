# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200" do
    get root_url
    assert_response :success
  end

  test "GET / renders application layout" do
    get root_url
    assert_select "header[role=banner]"
    assert_select "main[role=main]"
    assert_select "footer[role=contentinfo]"
  end

  test "GET / renders page title" do
    get root_url
    assert_select "title", /Asthma Buddy/
  end
end
