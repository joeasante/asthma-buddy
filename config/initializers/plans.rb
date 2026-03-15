# frozen_string_literal: true

PLANS = {
  free: {
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30
    }
  },
  premium: {
    trial_days: 30,
    pricing: {
      monthly: { display: "$7.99/month" },
      annual: { display: "$59.99/year", savings: "37%" }
    },
    features: {
      symptom_log_history_days: nil,  # unlimited
      peak_flow_history_days: nil     # unlimited
    }
  }
}.freeze
