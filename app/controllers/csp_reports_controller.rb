# frozen_string_literal: true

# Receives Content-Security-Policy violation reports from browsers.
# Inherits from ActionController::Base to bypass authentication and CSRF protection —
# browser CSP reports are unauthenticated and do not carry CSRF tokens.
class CspReportsController < ActionController::Base
  skip_forgery_protection
  rate_limit to: 10, within: 1.minute, with: -> { head :too_many_requests }

  def create
    body = request.body.read(512).to_s
    sanitized = body.gsub(/[\r\n\x1b]/, " ").truncate(500)
    Rails.logger.warn "[CSP Violation] #{sanitized}"
    head :no_content
  end
end
