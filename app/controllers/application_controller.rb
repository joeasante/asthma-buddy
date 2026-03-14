# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include ActionView::RecordIdentifier

  after_action :verify_authorized, unless: :skip_authorization?
  after_action :verify_policy_scoped_for_index, unless: :skip_authorization?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
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

  # Terminate idle authenticated sessions after 60 minutes of inactivity.
  # Only runs for authenticated users.
  IDLE_TIMEOUT = 60.minutes
  before_action :check_session_freshness, if: :authenticated?

  private

  def set_no_store_cache_for_authenticated_users
    response.headers["Cache-Control"] = "no-store" if authenticated?
  end

  def check_session_freshness
    return unless session[:last_seen_at]
    if Time.current - session[:last_seen_at].to_time > IDLE_TIMEOUT
      reset_session
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Your session expired due to inactivity. Please sign in again." }
        format.json { render json: { error: "Session expired" }, status: :unauthorized }
      end
    else
      session[:last_seen_at] = Time.current
    end
  end

  def set_notification_badge_count
    @unread_notification_count = Rails.cache.fetch(
      Notification.badge_cache_key(Current.user.id),
      expires_in: 5.minutes
    ) do
      Current.user.notifications.unread.count
    end
  end

  # --- Access control via ALLOWED_EMAILS env var ---
  # Set ALLOWED_EMAILS="joe@example.com,alice@example.com" in production
  # to restrict login and disable registration for everyone else.
  # Unset or blank = open to all (default).

  def allowed_emails
    @allowed_emails ||= ENV["ALLOWED_EMAILS"]&.split(",")&.map(&:strip)&.map(&:downcase)
  end

  def allowed_email?(email)
    allowed_emails.blank? || allowed_emails.include?(email.to_s.downcase)
  end

  def registration_open?
    allowed_emails.blank?
  end

  helper_method :registration_open?

  # --- Pundit skip mechanism ---
  # Controllers that handle unauthenticated access or have no actions
  # to authorize call `skip_pundit` at the class level.
  class_attribute :_skip_pundit, default: false

  def self.skip_pundit
    self._skip_pundit = true
  end

  def pundit_user
    Current.user
  end

  def skip_authorization?
    self.class._skip_pundit
  end

  def verify_policy_scoped_for_index
    # Skip if authorize was already called (controllers that scope via Current.user
    # use authorize instead of policy_scope for index actions).
    verify_policy_scoped if action_name == "index" && !pundit_policy_authorized?
  end

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, alert: "You are not authorized to perform this action.") }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end
end
