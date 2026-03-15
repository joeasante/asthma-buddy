# frozen_string_literal: true

PLANS = {
  free: {
    features: {
      symptom_log_history_days: 30,
      peak_flow_history_days: 30
    }
  },
  premium: {
    features: {
      symptom_log_history_days: nil,  # unlimited
      peak_flow_history_days: nil     # unlimited
    }
  }
}.freeze
