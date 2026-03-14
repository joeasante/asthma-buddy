# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  def index
    authorize User
    @users = User.order(created_at: :desc).limit(100)
    @total_user_count = User.count

    respond_to do |format|
      format.html
      format.json { render json: @users.as_json(only: %i[id email_address full_name role created_at last_sign_in_at sign_in_count]) }
    end
  end

  def toggle_admin
    @user = User.find(params[:id])

    # Explicit guard clauses with user-friendly messages (before Pundit)
    if @user == Current.user
      skip_authorization
      respond_to do |format|
        format.html { redirect_to admin_users_path, alert: "You cannot change your own admin status." }
        format.json { render json: { error: "You cannot change your own admin status." }, status: :forbidden }
      end
      return
    end

    if @user.admin? && User.admin.count <= 1
      skip_authorization
      respond_to do |format|
        format.html { redirect_to admin_users_path, alert: "Cannot remove the last admin." }
        format.json { render json: { error: "Cannot remove the last admin." }, status: :forbidden }
      end
      return
    end

    # Policy still enforces as a safety net
    authorize @user

    new_role = nil
    User.transaction do
      @user.lock!
      new_role = @user.admin? ? :member : :admin

      # Re-check with row-level lock to prevent TOCTOU race condition
      if new_role == :member && User.where(role: :admin).lock.count <= 1
        respond_to do |format|
          format.html { redirect_to admin_users_path, alert: "Cannot remove the last admin." }
          format.json { render json: { error: "Cannot remove the last admin." }, status: :conflict }
        end
        return
      end

      Rails.logger.info "[admin] #{Current.user.email_address} #{new_role == :admin ? 'granted' : 'revoked'} admin on #{@user.email_address}"
      @user.update!(role: new_role)
    end

    respond_to do |format|
      format.html { redirect_to admin_users_path, notice: "#{@user.email_address} is #{new_role == :admin ? 'now' : 'no longer'} an admin." }
      format.json { render json: { email: @user.email_address, role: @user.role } }
    end
  end
end
