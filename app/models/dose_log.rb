# frozen_string_literal: true

class DoseLog < ApplicationRecord
  belongs_to :user
  belongs_to :medication

  GINA_REVIEW_THRESHOLD = 3
  GINA_URGENT_THRESHOLD = 6

  validates :puffs, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :recorded_at, presence: true

  scope :chronological, -> { order(recorded_at: :desc) }
  after_create_commit  :check_low_stock
  after_create_commit  :invalidate_dashboard_cache
  after_destroy_commit :invalidate_dashboard_cache

  def self.gina_band(uses)
    if uses >= GINA_URGENT_THRESHOLD
      :urgent
    elsif uses >= GINA_REVIEW_THRESHOLD
      :review
    else
      :controlled
    end
  end

  private

    def check_low_stock
      Notification.create_low_stock_for(medication)
    end

    def invalidate_dashboard_cache
      Rails.cache.delete("dashboard_vars/#{user_id}/#{Date.current}")
    end
end
