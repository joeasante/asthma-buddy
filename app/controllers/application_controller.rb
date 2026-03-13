# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include ActionView::RecordIdentifier
  # Scope modern browser check to HTML requests only.
  # Non-browser clients (agents, API callers, curl) request JSON and must not be rejected.
  before_action do
    allow_browser(versions: :modern, block: :default) if request.format.html?
  end

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # JSON response convention: controllers use respond_to blocks with jbuilder views
  # for JSON alongside ERB views for HTML. Every resource action that creates/modifies
  # data must support `format.json` so agents can call endpoints programmatically.

  # PHI / HIPAA: prevent health data from being retained in browser or proxy caches.
  before_action :set_no_store_cache_for_authenticated_users

  # Precompute unread badge count once per request; views use @unread_notification_count.
  before_action :set_notification_badge_count, if: :authenticated?

  private

  def set_no_store_cache_for_authenticated_users
    response.headers["Cache-Control"] = "no-store" if authenticated?
  end

  def set_notification_badge_count
    @unread_notification_count = Rails.cache.fetch(
      Notification.badge_cache_key(Current.user.id),
      expires_in: 1.hour
    ) do
      Current.user.notifications.unread.count
    end
  end
end
