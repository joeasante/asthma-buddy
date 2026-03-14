# frozen_string_literal: true

# Use Rails.cache (Solid Cache / SQLite-backed in production) so throttle counters
# are shared across Puma workers. Falls back to MemoryStore in test (where Rails.cache
# is NullStore). Rack::Attack.reset! in test setup/teardown clears the MemoryStore.
Rack::Attack.cache.store = if Rails.env.test?
  ActiveSupport::Cache::MemoryStore.new
else
  Rails.cache
end

class Rack::Attack
  # Shared helper: extract Bearer token from Authorization header
  EXTRACT_API_TOKEN = lambda { |req|
    req.env["HTTP_AUTHORIZATION"]&.match(ApiAuthenticatable::BEARER_PATTERN)&.[](1)
  }

  # Throttle login attempts: 5 per IP per 20 seconds
  throttle("logins/ip", limit: 5, period: 20) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Throttle signup attempts: 3 per IP per hour
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/registration" && req.post?
  end

  # Throttle login attempts per email: 10 per 5 minutes (distributed brute-force protection)
  throttle("logins/email", limit: 10, period: 5.minutes) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  # Throttle API requests: 60 per minute per API key
  throttle("api/v1/requests", limit: 60, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/")
      token = EXTRACT_API_TOKEN.call(req)
      Digest::SHA256.hexdigest(token) if token.present?
    end
  end

  # Throttle unauthenticated API requests by IP (stricter limit)
  throttle("api/v1/unauthenticated", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/api/v1/")
      token = EXTRACT_API_TOKEN.call(req)
      req.ip unless token.present?
    end
  end

  # Custom response for throttled requests — format-aware (JSON or plain text)
  self.throttled_responder = lambda do |req|
    matched = req.env["rack.attack.matched"]

    if matched.start_with?("api/v1/")
      # API throttle: return JSON error with Retry-After header
      match_data = req.env["rack.attack.match_data"]
      retry_after = match_data[:period] - (Time.now.to_i % match_data[:period])

      body = { error: { status: 429, message: "Rate limit exceeded. Try again later.", details: nil } }.to_json

      [ 429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s }, [ body ] ]
    else
      # Web throttle: existing behavior
      message = case matched
      when "logins/ip", "logins/email"
                  "Too many sign-in attempts. Please wait before trying again."
      when "signups/ip"
                  "Too many sign-up attempts from this IP address. Please try again later."
      else
                  "Too many requests. Please try again later."
      end

      if req.env["HTTP_ACCEPT"]&.include?("application/json") || req.content_type&.include?("application/json")
        [ 429, { "Content-Type" => "application/json" }, [ { error: message }.to_json ] ]
      else
        [ 429, { "Content-Type" => "text/plain" }, [ message ] ]
      end
    end
  end
end

# Disable rack-attack in the test environment by default so it does not interfere
# with unrelated tests. RateLimitingTest re-enables it selectively in setup/teardown.
Rack::Attack.enabled = false if Rails.env.test?
