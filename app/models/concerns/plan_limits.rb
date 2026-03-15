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
    return "admin" if admin? && sub.nil?
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

  def has_had_subscription?
    Pay::Subscription.joins(:customer)
      .where(pay_customers: { owner_type: "User", owner_id: id })
      .exists?
  end

  def history_cutoff_date(feature_key)
    days = plan_features[feature_key]
    return nil if days.nil?

    days.days.ago.beginning_of_day
  end

  # Returns [effective_start_date, history_limited?] after applying plan-based history limits
  def apply_history_limit(feature_key, start_date)
    cutoff = history_cutoff_date(feature_key)
    effective_start = [ start_date, cutoff&.to_date ].compact.max
    [ effective_start, cutoff.present? ]
  end

  private

  def current_subscription
    return @_current_subscription if defined?(@_current_subscription)
    @_current_subscription = payment_processor&.subscription
  end
end
