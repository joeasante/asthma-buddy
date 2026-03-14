# frozen_string_literal: true

class Admin::DashboardController < Admin::BaseController
  def index
    @total_users    = User.count
    @new_this_week  = User.where(created_at: 1.week.ago..).count
    @new_this_month = User.where(created_at: 1.month.ago..).count
    @wau            = User.where(last_sign_in_at: 7.days.ago..).count
    @mau            = User.where(last_sign_in_at: 30.days.ago..).count
    @never_returned = User.where(sign_in_count: 1).count
    @recent_signups = User.order(created_at: :desc).limit(10)
    @most_active    = User.order(sign_in_count: :desc).limit(10)
  end
end
