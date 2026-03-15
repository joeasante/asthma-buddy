# frozen_string_literal: true

class BillingMailer < ApplicationMailer
  def trial_ending_soon(user)
    @user = user
    @trial_ends_at = user.trial_ends_at
    @plan_display = resolve_plan_display(user)

    mail(
      to: @user.email_address,
      subject: "Your Asthma Buddy trial ends in 3 days"
    )
  end

  private

  def resolve_plan_display(user)
    processor_plan = user.payment_processor&.subscription&.processor_plan
    if processor_plan == Rails.application.credentials.dig(:stripe, :annual_price_id)
      PLANS[:premium][:pricing][:annual][:display]
    else
      PLANS[:premium][:pricing][:monthly][:display]
    end
  end
end
