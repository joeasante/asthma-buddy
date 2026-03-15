# frozen_string_literal: true

module PlanLimits
  extend ActiveSupport::Concern

  # Trial users ARE premium — explicit check avoids implicit dependency on Pay's active? behavior
  def premium?
    return true if admin?
    sub = current_subscription
    sub.present? && (sub.active? || sub.on_trial?) && sub.status != "paused"
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
    if sub.status == "paused"
      "paused"
    elsif sub.on_trial?
      "trialing"
    elsif sub.active? && sub.ends_at.present?
      "cancelling"
    elsif sub.active?
      "active"
    else
      sub.status
    end
  end

  def on_trial?
    current_subscription&.on_trial? || false
  end

  def trial_ends_at
    current_subscription&.trial_ends_at
  end

  def paused?
    current_subscription&.status == "paused"
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
    payment_processor&.subscription
  end
end
