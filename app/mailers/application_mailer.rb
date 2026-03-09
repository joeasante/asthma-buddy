# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM_ADDRESS", "Asthma Buddy <noreply@asthmabuddy.app>")
  layout "mailer"
end
