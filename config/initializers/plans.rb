# frozen_string_literal: true

PLANS = {
  free: {
    name: "Free",
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30,
      api_access: false,
      data_export: false
    }
  },
  premium: {
    name: "Premium",
    features: {
      symptom_log_history_days: nil,  # unlimited
      peak_flow_history_days: nil,    # unlimited
      api_access: true,
      data_export: true
    }
  }
}.freeze
