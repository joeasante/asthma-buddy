# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200" do
    get root_url
    assert_response :success
  end

  test "GET / renders application layout" do
    get root_url
    assert_select "header"
    assert_select "main#main-content"
    assert_select "main", count: 1
    assert_select "footer"
  end

  test "GET / renders page title" do
    get root_url
    assert_select "title", "Asthma Buddy — Breathe easier. Every day."
  end
end
