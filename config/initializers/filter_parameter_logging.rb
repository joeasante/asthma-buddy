# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  # Health data — prevent PHI from appearing in server logs
  /peak_flow_reading\[value\]/, /peak_flow_reading\[recorded_at\]/,
  /personal_best_record\[value\]/
]
