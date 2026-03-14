# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  def index
    authorize User
    @users = policy_scope(User).order(created_at: :desc).limit(100)
    @total_user_count = User.count

    respond_to do |format|
      format.html
      format.json { render json: @users.as_json(only: %i[id email_address full_name role created_at last_sign_in_at sign_in_count]) }
    end
  end

  def toggle_admin
    @user = User.find(params[:id])
    authorize @user

    new_role = @user.admin? ? :member : :admin
    Rails.logger.info "[admin] #{Current.user.email_address} #{new_role == :admin ? 'granted' : 'revoked'} admin on #{@user.email_address}"
    @user.update!(role: new_role)

    respond_to do |format|
      format.html { redirect_to admin_users_path, notice: "#{@user.email_address} is #{new_role == :admin ? 'now' : 'no longer'} an admin." }
      format.json { render json: { email: @user.email_address, role: @user.role } }
    end
  end
end
