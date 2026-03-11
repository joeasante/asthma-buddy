# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[mark_read]

  def index
    @notifications       = Current.user.notifications.newest_first
    @unread_count        = Current.user.notifications.unread.count
    @last_notification   = @notifications.first

    respond_to do |format|
      format.html
      format.json do
        render json: {
          notifications: @notifications.as_json(only: %i[id notification_type body read created_at]),
          unread_count:  @unread_count
        }
      end
    end
  end

  def mark_read
    destination = resolve_notification_path(@notification)
    @notification.update!(read: true)
    @unread_count      = Current.user.notifications.unread.count
    @last_notification = Current.user.notifications.newest_first.first

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to destination }
      format.json { render json: { id: @notification.id, read: true, unread_count: @unread_count } }
    end
  end

  def mark_all_read
    @notifications     = Current.user.notifications.unread.to_a
    @notifications.each { |n| n.read = true }
    Current.user.notifications.unread.update_all(read: true)
    @unread_count      = 0
    @last_notification = Current.user.notifications.newest_first.first

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to notifications_path }
      format.json { render json: { unread_count: 0 } }
    end
  end

  private

  def set_notification
    @notification = Current.user.notifications.find(params[:id])
  end

  def resolve_notification_path(notification)
    case notification.notification_type
    when "low_stock"   then settings_medications_path
    when "missed_dose" then root_path
    else                    root_path
    end
  end
end
