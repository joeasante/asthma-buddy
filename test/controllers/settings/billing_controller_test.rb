# frozen_string_literal: true

require "test_helper"

class Settings::BillingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @admin = users(:admin_user)
  end

  # -- show --

  test "show renders for authenticated user" do
    sign_in_as @user
    get settings_billing_path
    assert_response :success
    assert_select "h1", "Billing"
  end

  test "show redirects unauthenticated user to sign-in" do
    get settings_billing_path
    assert_redirected_to new_session_path
  end

  test "show displays Free plan for users without subscriptions" do
    sign_in_as @user
    get settings_billing_path
    assert_select "strong", "Free"
    assert_select ".badge--disabled", "Free"
  end

  test "show displays free plan limits for free users" do
    sign_in_as @user
    get settings_billing_path
    assert_select ".billing-limits" do
      assert_select "li", text: /30 days symptom log history/
      assert_select "li", text: /No API access/
    end
  end

  test "show displays upgrade button for free users" do
    sign_in_as @user
    get settings_billing_path
    assert_select "button", text: "Upgrade to Premium"
  end

  test "show does not display manage subscription button for free users" do
    sign_in_as @user
    get settings_billing_path
    assert_select "button", text: "Manage Subscription", count: 0
  end

  test "show displays Premium Admin label for admin users" do
    sign_in_as @admin
    get settings_billing_path
    assert_select "strong", "Premium (Admin)"
  end

  test "show does not display manage subscription button for admin users" do
    sign_in_as @admin
    get settings_billing_path
    assert_select "button", text: "Manage Subscription", count: 0
  end

  test "show does not display upgrade button for admin users" do
    sign_in_as @admin
    get settings_billing_path
    assert_select "button", text: "Upgrade to Premium", count: 0
  end

  # -- checkout policy enforcement --

  test "checkout is denied for premium users" do
    # Make user premium via subscription
    @user.set_payment_processor :stripe
    @user.payment_processor.subscriptions.create!(
      name: "default",
      processor_id: "sub_test_checkout",
      processor_plan: "price_test",
      status: "active",
      type: "Pay::Stripe::Subscription"
    )
    @user.payment_processor.reload

    sign_in_as @user
    post checkout_settings_billing_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # -- portal policy enforcement --

  test "portal is denied for free users" do
    sign_in_as @user
    post portal_settings_billing_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "portal is denied for admin users" do
    sign_in_as @admin
    post portal_settings_billing_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # -- checkout and portal buttons have data-turbo=false --

  test "checkout button has data-turbo false attribute" do
    sign_in_as @user
    get settings_billing_path
    assert_select "form[action='#{checkout_settings_billing_path}']" do
      assert_select "button[data-turbo='false']", text: "Upgrade to Premium"
    end
  end

  # -- settings nav includes billing card --

  test "settings page includes billing card" do
    sign_in_as @user
    get settings_path
    assert_select "a[href='#{settings_billing_path}']" do
      assert_select ".settings-nav-title", /Billing/
    end
  end
end
