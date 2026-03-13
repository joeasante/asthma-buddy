# frozen_string_literal: true

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
