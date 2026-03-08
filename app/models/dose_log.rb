# frozen_string_literal: true
class DoseLog < ApplicationRecord
  belongs_to :user
  belongs_to :medication

  validates :puffs, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :recorded_at, presence: true

  scope :chronological, -> { order(recorded_at: :desc) }
  scope :for_medication, ->(medication) { where(medication: medication) }
end
