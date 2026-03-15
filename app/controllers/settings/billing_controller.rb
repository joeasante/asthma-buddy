# frozen_string_literal: true

class Settings::BillingController < Settings::BaseController
  def show
    authorize :billing
    @user = Current.user
    @subscription = @user.payment_processor&.subscription
  end

  def checkout
    authorize :billing, :checkout?
    user = Current.user
    user.set_payment_processor :stripe

    checkout_session = user.payment_processor.checkout(
      mode: "subscription",
      line_items: Rails.application.credentials.dig(:stripe, :premium_price_id),
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def portal
    authorize :billing, :portal?
    portal_session = Current.user.payment_processor.billing_portal(
      return_url: settings_billing_url
    )
    redirect_to portal_session.url, allow_other_host: true
  end
end
