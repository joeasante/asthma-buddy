# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  after_action :verify_authorized

  def index
    authorize :admin_dashboard, :index?
    @registration_open = SiteSetting.registration_open?
    @total_users    = User.count
    @new_this_week  = User.where(created_at: 1.week.ago..).count
    @new_this_month = User.where(created_at: 1.month.ago..).count
    @wau            = User.where(last_sign_in_at: 7.days.ago..).count
    @mau            = User.where(last_sign_in_at: 30.days.ago..).count
    @never_returned = User.where(sign_in_count: 1).count
    @recent_signups = User.order(created_at: :desc).limit(10)
    @most_active    = User.order(sign_in_count: :desc).limit(10)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          total_users: @total_users,
          new_this_week: @new_this_week,
          new_this_month: @new_this_month,
          wau: @wau,
          mau: @mau,
          never_returned: @never_returned,
          recent_signups: @recent_signups.as_json(only: %i[id email_address full_name created_at]),
          most_active: @most_active.as_json(only: %i[id email_address sign_in_count last_sign_in_at])
        }
      end
    end
  end
end
