# frozen_string_literal: true
class User < ApplicationRecord
  has_secure_password
  # :delete_all skips callbacks — sessions have none, and bulk DELETE is more efficient than per-record :destroy
  has_many :sessions, dependent: :delete_all
  has_many :symptom_logs, dependent: :destroy
  has_many :peak_flow_readings, dependent: :destroy
  has_many :personal_best_records, dependent: :destroy
  has_many :medications, dependent: :destroy
  has_one_attached :avatar

  validates :avatar,
    content_type: { in: %w[image/jpeg image/png image/webp image/gif],
                    message: "must be a JPEG, PNG, WebP, or GIF" },
    size: { less_than: 5.megabytes, message: "must be smaller than 5 MB" },
    if: -> { avatar.attached? }
  validates :full_name, length: { maximum: 100 }, allow_blank: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true,
                             uniqueness: { case_sensitive: false },
                             format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? || new_record? }

  generates_token_for :email_verification, expires_in: 24.hours
  generates_token_for :password_reset, expires_in: 1.hour do
    password_salt.last(10)
  end
end
