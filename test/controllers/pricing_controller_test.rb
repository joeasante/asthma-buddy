# frozen_string_literal: true

require "test_helper"

class PricingControllerTest < ActionDispatch::IntegrationTest
  test "GET /pricing returns 200 for unauthenticated users" do
    get pricing_path
    assert_response :success
  end

  test "GET /pricing returns 200 for authenticated users" do
    sign_in_as users(:verified_user)
    get pricing_path
    assert_response :success
  end

  test "pricing page contains monthly price" do
    get pricing_path
    assert_match PLANS[:premium][:pricing][:monthly][:display], response.body
  end

  test "pricing page contains annual price" do
    get pricing_path
    assert_match PLANS[:premium][:pricing][:annual][:display], response.body
  end

  test "pricing page contains free trial messaging" do
    get pricing_path
    assert_match "free trial", response.body.downcase
  end

  test "pricing page shows Get Started for unauthenticated users" do
    get pricing_path
    assert_select "a", text: "Get Started"
  end

  test "pricing page shows Start Free Trial for free authenticated users" do
    sign_in_as users(:verified_user)
    get pricing_path
    assert_select "button", /Start Free Trial/
  end

  test "pricing page shows You're on Premium for premium users" do
    user = users(:admin_user) # admin is always premium
    sign_in_as user
    get pricing_path
    assert_match "on Premium", response.body
  end

  test "pricing link appears in logged-out header nav" do
    get pricing_path
    assert_select "nav[aria-label='Main navigation'] a[href='#{pricing_path}']", text: "Pricing"
  end

  test "pricing link appears in logged-out footer" do
    get pricing_path
    assert_select "footer nav a[href='#{pricing_path}']", text: "Pricing"
  end

  test "pricing link appears in logged-in footer" do
    sign_in_as users(:verified_user)
    get pricing_path
    assert_select "footer nav a[href='#{pricing_path}']", text: "Pricing"
  end
end
