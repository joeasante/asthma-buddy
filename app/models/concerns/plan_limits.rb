# frozen_string_literal: true

module PlanLimits
  extend ActiveSupport::Concern

  def premium?
    return @_premium if defined?(@_premium)
    @_premium = admin? || current_subscription&.active? || false
  end

  def free?
    !premium?
  end

  def plan_name
    premium? ? "Premium" : "Free"
  end

  def plan_features
    premium? ? PLANS[:premium][:features] : PLANS[:free][:features]
  end

  def subscription_status
    sub = current_subscription
    return "none" unless sub
    if sub.active? && sub.ends_at.present?
      "cancelling"
    elsif sub.active?
      "active"
    else
      sub.status
    end
  end

  def next_billing_date
    current_subscription&.current_period_end
  end

  def history_cutoff_date(feature_key)
    days = plan_features[feature_key]
    return nil if days.nil?

    days.days.ago.beginning_of_day
  end

  private

  def current_subscription
    return @_current_subscription if defined?(@_current_subscription)
    @_current_subscription = payment_processor&.subscription
  end
end
