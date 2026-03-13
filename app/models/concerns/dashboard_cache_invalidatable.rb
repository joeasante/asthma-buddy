# frozen_string_literal: true

# Shared concern for models whose changes must bust the dashboard vars cache.
# Exposes dashboard_cache_key as a module-level method so the controller
# concern (DashboardVariables) can build the same key without cross-layer
# coupling. Include in any model that has after_commit cache invalidation.
module DashboardCacheInvalidatable
  extend ActiveSupport::Concern

  def self.dashboard_cache_key(user_id, date = Date.current)
    "dashboard_vars/#{user_id}/#{date}"
  end

  private

    def invalidate_dashboard_cache
      Rails.cache.delete(DashboardCacheInvalidatable.dashboard_cache_key(user_id))
    end
end
