# frozen_string_literal: true

# Use a dedicated MemoryStore so throttle counters persist across requests.
# Rack::Attack defaults to Rails.cache, which is NullStore in the test environment.
# The MemoryStore is reset between test runs via Rack::Attack.reset! in test setup/teardown.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  # Throttle login attempts: 5 per IP per 20 seconds
  throttle("logins/ip", limit: 5, period: 20) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Throttle signup attempts: 3 per IP per hour
  throttle("signups/ip", limit: 3, period: 1.hour) do |req|
    req.ip if req.path == "/registration" && req.post?
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |_env|
    [429, { "Content-Type" => "text/plain" }, ["Too many requests. Please wait before trying again."]]
  end
end

# Disable rack-attack in the test environment by default so it does not interfere
# with unrelated tests. RateLimitingTest re-enables it selectively in setup/teardown.
Rack::Attack.enabled = false if Rails.env.test?
