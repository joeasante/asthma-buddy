# frozen_string_literal: true

# Removes sessions older than 30 days. Sessions accumulate indefinitely without
# pruning — the (created_at) index on sessions exists specifically for this query.
# Scheduled nightly at 2am via Solid Queue (config/recurring.yml).
class PruneSessionsJob < ApplicationJob
  queue_as :default

  def perform
    deleted = Session.where("created_at < ?", 30.days.ago).delete_all
    Rails.logger.info "[PruneSessions] Pruned #{deleted} sessions older than 30 days"
  end
end
