# frozen_string_literal: true

module PlanLimits
  extend ActiveSupport::Concern

  def premium?
    admin? || payment_processor&.subscription&.active?
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
    sub = payment_processor&.subscription
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
    payment_processor&.subscription&.current_period_end
  end

  def history_cutoff_date(feature_key)
    days = plan_features[feature_key]
    return nil if days.nil? # nil means unlimited

    days.days.ago.beginning_of_day
  end
end
