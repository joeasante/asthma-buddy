# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc)
  end

  def toggle_admin
    user = User.find(params[:id])

    if user == Current.user
      return redirect_back(fallback_location: admin_users_path,
                           alert: "You cannot change your own admin status.")
    end

    if User.where(admin: true).count == 1 && user.admin?
      return redirect_back(fallback_location: admin_users_path,
                           alert: "Cannot remove the last admin. Grant admin to another user first.")
    end

    new_state = !user.admin?
    Rails.logger.info "[admin] #{Current.user.email_address} #{new_state ? 'granted' : 'revoked'} admin on #{user.email_address}"
    user.update!(admin: new_state)
    redirect_to admin_users_path,
                notice: "#{user.email_address} is #{new_state ? 'now' : 'no longer'} an admin."
  end
end
