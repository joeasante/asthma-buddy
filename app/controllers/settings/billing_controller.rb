# frozen_string_literal: true

class Settings::BillingController < Settings::BaseController
  def show
    authorize :billing
    @user = Current.user
    @subscription = @user.payment_processor&.subscription
  end

  def checkout
    authorize :billing, :checkout?
    Current.user.set_payment_processor :stripe

    plan = params[:plan]
    unless %w[monthly annual].include?(plan)
      plan = "monthly"
    end

    price_id = plan == "annual" ?
      Rails.application.credentials.dig(:stripe, :annual_price_id) :
      Rails.application.credentials.dig(:stripe, :monthly_price_id)

    subscription_data = Current.user.has_had_subscription? ? {} : { trial_period_days: PLANS[:premium][:trial_days] }

    checkout_session = Current.user.payment_processor.checkout(
      mode: "subscription",
      line_items: price_id,
      subscription_data: subscription_data,
      success_url: settings_billing_url,
      cancel_url: settings_billing_url
    )

    redirect_to checkout_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError => e
    Rails.logger.error("[Billing] Checkout failed: #{e.message}")
    redirect_to settings_billing_path, alert: "Unable to start checkout. Please try again."
  end

  def portal
    authorize :billing, :portal?
    portal_session = Current.user.payment_processor.billing_portal(
      return_url: settings_billing_url
    )
    redirect_to portal_session.url, allow_other_host: true
  rescue Pay::Error, Stripe::StripeError => e
    Rails.logger.error("[Billing] Portal failed: #{e.message}")
    redirect_to settings_billing_path, alert: "Unable to open billing portal. Please try again."
  end
end
