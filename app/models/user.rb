# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  enum :role, { member: 0, admin: 1 }, default: :member
  # :delete_all skips callbacks — sessions have none, and bulk DELETE is more efficient than per-record :destroy
  has_many :sessions,             dependent: :delete_all
  has_many :symptom_logs,         dependent: :destroy       # has_rich_text :notes — needs callbacks for ActionText cleanup
  has_many :peak_flow_readings,   dependent: :delete_all    # no destroy callbacks — bulk DELETE is safe and faster
  has_many :personal_best_records, dependent: :delete_all   # no destroy callbacks — bulk DELETE is safe
  has_many :medications,          dependent: :destroy       # cascades to dose_logs via its own dependent: :destroy
  has_many :dose_logs,            dependent: :delete_all    # no destroy callbacks; medications cascade first
  has_many :health_events,        dependent: :destroy       # has_rich_text :notes — needs callbacks for ActionText cleanup
  has_many :notifications,        dependent: :delete_all    # no destroy callbacks — bulk DELETE is safe
  has_one_attached :avatar
  before_destroy :purge_avatar_attachment
  after_create_commit :notify_admin_of_signup

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

  encrypts :otp_secret, deterministic: false
  encrypts :otp_recovery_codes, deterministic: false

  def onboarding_complete?
    onboarding_personal_best_done? && onboarding_medication_done?
  end

  # -- MFA --

  def otp_required_for_login?
    otp_secret.present? && self[:otp_required_for_login]
  end

  def verify_otp(code)
    return false if otp_secret.blank? || code.blank?

    totp = ROTP::TOTP.new(otp_secret, issuer: "Asthma Buddy")
    timestamp = totp.verify(code.to_s, drift_behind: 15, after: last_otp_at.to_i)
    return false unless timestamp

    update!(last_otp_at: Time.at(timestamp))
    true
  end

  def verify_recovery_code(code)
    return false if code.blank?

    normalized = code.to_s.strip.downcase.delete("-")
    codes = recovery_codes_array
    index = codes.index(normalized)
    return false unless index

    codes.delete_at(index)
    update!(otp_recovery_codes: codes.join(","))
    true
  end

  def enable_mfa!(secret)
    codes = generate_recovery_codes
    update!(
      otp_secret: secret,
      otp_required_for_login: true,
      otp_recovery_codes: codes.join(","),
      last_otp_at: nil
    )
    codes
  end

  def regenerate_recovery_codes!
    codes = generate_recovery_codes
    update!(otp_recovery_codes: codes.join(","))
    codes
  end

  def disable_mfa!
    update!(
      otp_secret: nil,
      otp_required_for_login: false,
      otp_recovery_codes: nil,
      last_otp_at: nil
    )
  end

  def recovery_codes
    recovery_codes_array
  end

  def recovery_codes_remaining
    recovery_codes_array.size
  end

  private

  def purge_avatar_attachment
    avatar.purge if avatar.attached?
  end

  def recovery_codes_array
    (otp_recovery_codes || "").split(",").reject(&:blank?)
  end

  def generate_recovery_codes
    10.times.map { SecureRandom.hex(5) }
  end

  def notify_admin_of_signup
    return unless Rails.application.credentials.admin_email.present?

    AdminMailer.new_signup(self).deliver_later
  end
end
