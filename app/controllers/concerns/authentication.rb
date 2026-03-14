# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie&.tap { |s| refresh_session_cookie(s) }
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id])
    end

    def refresh_session_cookie(session)
      cookies.signed[:session_id] = { value: session.id, httponly: true, secure: !Rails.env.local?, same_site: :lax, expires: 2.weeks.from_now }
    end

    def request_authentication
      respond_to do |format|
        format.html do
          # url_from validates same-origin to prevent open redirect; falls back to root_url for external URLs.
          # main_app prefix ensures route resolution uses the app's routes, not a mounted engine's.
          session[:return_to_after_authenticating] = url_from(request.url) || main_app.root_url
          redirect_to main_app.new_session_path
        end
        format.json { render json: { error: "Authentication required" }, status: :unauthorized }
      end
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || main_app.root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        refresh_session_cookie(session)
      end
    end

    def complete_sign_in(user)
      start_new_session_for user
      session[:last_seen_at] = Time.current
      User.where(id: user.id).update_all(
        [ "last_sign_in_at = ?, sign_in_count = sign_in_count + 1", Time.current ]
      )
    end

    def terminate_session
      Current.session&.destroy
      cookies.delete(:session_id)
    end
end
