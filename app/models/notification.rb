# frozen_string_literal: true

class Notification < ApplicationRecord
  NOTIFIABLE_TYPES = %w[Medication].freeze

  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :notification_type, {
    low_stock:   0,
    missed_dose: 1,
    system:      2
  }, validate: true

  validates :body, presence: true
  validates :notifiable_type, inclusion: { in: NOTIFIABLE_TYPES }, allow_nil: true

  scope :unread,       -> { where(read: false) }
  scope :newest_first, -> { order(created_at: :desc) }
  scope :pruneable,    -> { where(read: true).where("created_at < ?", 90.days.ago) }

  after_commit -> { invalidate_badge_cache }, on: :create
  after_commit -> { invalidate_badge_cache }, on: :update, if: :saved_change_to_read?

  def self.badge_cache_key(user_id)
    "unread_notifications/#{user_id}"
  end

  # Creates a low_stock notification for a medication if none already exists.
  # Called after a DoseLog is saved; safe to call frequently — deduplication is inside.
  def self.create_low_stock_for(medication)
    user = medication.user
    return unless medication.low_stock?
    return if exists?(user: user, notification_type: :low_stock, notifiable: medication, read: false)

    create!(
      user:              user,
      notification_type: :low_stock,
      notifiable:        medication,
      body:              "#{medication.name} has fewer than #{Medication::LOW_STOCK_DAYS} days of supply remaining. Consider requesting a refill."
    )
  end

  private

    def invalidate_badge_cache
      Rails.cache.delete(Notification.badge_cache_key(user_id))
    end
end
