# frozen_string_literal: true

# Logs connection pool wait times that exceed 100ms. Threads waiting this long
# for a pool connection indicate the pool is undersized relative to thread count.
# This surfaces contention that looks like slow queries in logs but isn't.
ActiveSupport::Notifications.subscribe("wait.active_record_connection_pool") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  if event.duration > 100
    Rails.logger.warn "[ConnectionPool] Waited #{event.duration.round}ms for a connection " \
      "on #{event.payload[:pool_name]}"
  end
end
