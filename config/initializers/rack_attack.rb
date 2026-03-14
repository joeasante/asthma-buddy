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

  # Custom response for throttled requests — format-aware (JSON or plain text)
  self.throttled_responder = lambda do |req|
    message = case req.env["rack.attack.matched"]
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

# Disable rack-attack in the test environment by default so it does not interfere
# with unrelated tests. RateLimitingTest re-enables it selectively in setup/teardown.
Rack::Attack.enabled = false if Rails.env.test?
