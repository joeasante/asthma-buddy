class AddNotificationIndexes < ActiveRecord::Migration[8.1]
  def change
    # Deduplication speed-up: covers the exists? queries in create_low_stock_for
    # and MissedDoseCheckJob (todo 268)
    add_index :notifications,
              %i[user_id notification_type notifiable_type notifiable_id],
              name: "index_notifications_deduplication"

    # TOCTOU guard: prevents two concurrent requests from creating duplicate unread
    # notifications for the same notifiable (todo 258)
    add_index :notifications,
              %i[user_id notifiable_type notifiable_id notification_type],
              where: "read = 0",
              unique: true,
              name: "index_notifications_unique_unread_per_notifiable"
  end
end
