# frozen_string_literal: true

PLANS = {
  free: {
    name: "Free",
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30,
      api_access: false,
      health_report_export: false
    }
  },
  premium: {
    name: "Premium",
    trial_days: 30,
    pricing: {
      monthly: { amount: 799, currency: "usd", display: "$7.99/month" },
      annual: { amount: 5999, currency: "usd", display: "$59.99/year", savings: "37%" }
    },
    features: {
      symptom_log_history_days: nil,  # unlimited
      peak_flow_history_days: nil,    # unlimited
      api_access: true,
      health_report_export: true
    }
  }
}.freeze
