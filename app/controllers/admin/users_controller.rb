# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(created_at: :desc).limit(100)
    @total_user_count = User.count

    respond_to do |format|
      format.html
      format.json { render json: @users.as_json(only: %i[id email_address full_name admin created_at last_sign_in_at sign_in_count]) }
    end
  end

  def toggle_admin
    user = User.find(params[:id])

    if user == Current.user
      return redirect_back(fallback_location: admin_users_path,
                           alert: "You cannot change your own admin status.")
    end

    new_state = nil
    User.transaction do
      if User.where(admin: true).count == 1 && user.admin?
        return redirect_back(fallback_location: admin_users_path,
                             alert: "Cannot remove the last admin. Grant admin to another user first.")
      end

      new_state = !user.admin?
      Rails.logger.info "[admin] #{Current.user.email_address} #{new_state ? 'granted' : 'revoked'} admin on #{user.email_address}"
      user.update!(admin: new_state)
    end
    respond_to do |format|
      format.html { redirect_to admin_users_path, notice: "#{user.email_address} is #{new_state ? 'now' : 'no longer'} an admin." }
      format.json { render json: { email: user.email_address, admin: new_state } }
    end
  end
end
