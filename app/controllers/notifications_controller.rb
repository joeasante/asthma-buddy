# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :require_authentication
  before_action :set_notification, only: [:mark_read]

  def index
    @notifications = Current.user.notifications.newest_first
    @unread_count  = Current.user.notifications.unread.count
  end

  def mark_read
    # Handle broken notifiable target — medication may have been deleted
    destination = resolve_notification_path(@notification)

    @notification.update!(read: true)
    @unread_count = Current.user.notifications.unread.count

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to destination }
    end
  end

  def mark_all_read
    Current.user.notifications.unread.update_all(read: true)
    @notifications = Current.user.notifications.newest_first
    @unread_count  = 0

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path }
    end
  end

  private

  def set_notification
    @notification = Current.user.notifications.find(params[:id])
  end

  # Resolves the navigation path for a notification.
  # If the notifiable record no longer exists (deleted medication, etc.),
  # falls back to a safe path and auto-marks the notification read.
  def resolve_notification_path(notification)
    case notification.notification_type
    when "low_stock"
      begin
        notification.notifiable  # trigger load — raises if deleted
        settings_medications_path
      rescue ActiveRecord::RecordNotFound
        notification.update_columns(read: true)
        settings_medications_path
      end
    when "missed_dose"
      begin
        notification.notifiable
        root_path
      rescue ActiveRecord::RecordNotFound
        notification.update_columns(read: true)
        root_path
      end
    else
      root_path
    end
  end
end
