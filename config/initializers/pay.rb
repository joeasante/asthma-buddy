# frozen_string_literal: true

Pay.setup do |config|
  config.business_name = "Asthma Buddy"
  config.business_address = ""
  config.application_name = "Asthma Buddy"
  config.support_email = Rails.application.credentials.dig(:admin_email) || "support@example.com"
  config.enabled_processors = [ :stripe ]
  config.send_emails = false # Disable Pay's built-in emails for MVP; use app's own mailers later
end
