# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, {
    low_stock:   0,
    missed_dose: 1,
    system:      2
  }, validate: true

  validates :body, presence: true

  scope :unread,       -> { where(read: false) }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :pruneable,    -> { where(read: true).where("created_at < ?", 90.days.ago) }

  # Creates a low_stock notification for a medication if none exists unread for it.
  # Called after a DoseLog is saved; safe to call frequently — deduplication is inside.
  def self.create_low_stock_for(medication)
    user = medication.user
    return unless medication.low_stock?
    return if exists?(user: user, notification_type: :low_stock, notifiable: medication, read: false)

    create!(
      user:              user,
      notification_type: :low_stock,
      notifiable:        medication,
      body:              "#{medication.name} has fewer than 14 days of supply remaining. Consider requesting a refill.",
      read:              false
    )
  end
end
