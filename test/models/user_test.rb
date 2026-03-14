# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "valid user is valid" do
    user = User.new(email_address: "newuser@example.com", password: "password123", password_confirmation: "password123")
    assert user.valid?
  end

  test "email_address presence is required" do
    user = User.new(email_address: "", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address uniqueness is enforced" do
    existing = users(:verified_user)
    duplicate = User.new(email_address: existing.email_address, password: "password123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email_address uniqueness is case-insensitive" do
    existing = users(:verified_user)
    duplicate = User.new(email_address: existing.email_address.upcase, password: "password123")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email_address format validation rejects invalid emails" do
    user = User.new(email_address: "not-an-email", password: "password123")
    assert_not user.valid?
    assert user.errors[:email_address].any?
  end

  test "email_address is normalized to lowercase and stripped" do
    user = User.new(email_address: "  ALICE@EXAMPLE.COM  ", password: "password123")
    assert_equal "alice@example.com", user.email_address
  end

  test "password minimum length of 8 is enforced" do
    user = User.new(email_address: "newuser@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "password of exactly 8 characters is valid" do
    user = User.new(email_address: "newuser@example.com", password: "exactly8")
    assert user.valid?
  end

  # -- onboarding_complete? --

  test "onboarding_complete? returns false when neither flag is set" do
    assert_not users(:new_user).onboarding_complete?
  end

  test "onboarding_complete? returns false when only personal_best_done is true" do
    user = users(:new_user)
    user.update!(onboarding_personal_best_done: true)
    assert_not user.onboarding_complete?
  end

  test "onboarding_complete? returns false when only medication_done is true" do
    user = users(:new_user)
    user.update!(onboarding_medication_done: true)
    assert_not user.onboarding_complete?
  end

  test "onboarding_complete? returns true when both flags are true" do
    assert users(:verified_user).onboarding_complete?
  end

  # -- role enum --

  test "new user defaults to member role" do
    user = User.new(email_address: "roletest@example.com", password: "password123")
    assert_equal "member", user.role
    assert user.member?
  end

  test "admin? returns true for admin role" do
    assert users(:admin_user).admin?
  end

  test "member? returns true for member role" do
    assert users(:verified_user).member?
  end

  test "role can be changed to admin" do
    user = users(:verified_user)
    assert user.member?
    user.admin!
    assert user.admin?
  end

  # -- sign_in_count --

  test "sign_in_count defaults to 0 on a new user record" do
    user = User.new(email_address: "newtrack@example.com", password: "password123")
    # Default is enforced at the DB level — not a Ruby default
    assert_equal 0, user.sign_in_count
  end

  # -- MFA: otp_required_for_login? --

  test "otp_required_for_login? returns false when MFA not enabled" do
    assert_not users(:verified_user).otp_required_for_login?
  end

  test "otp_required_for_login? returns true when MFA enabled" do
    user = users(:mfa_user)
    user.enable_mfa!(ROTP::Base32.random)
    assert user.otp_required_for_login?
  end

  # -- MFA: enable_mfa! --

  test "enable_mfa! sets otp_secret and returns 10 recovery codes" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    codes = user.enable_mfa!(secret)

    assert_equal 10, codes.size
    assert user.otp_required_for_login?
    assert_equal secret, user.otp_secret
  end

  # -- MFA: verify_otp --

  test "verify_otp accepts valid TOTP code" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    user.enable_mfa!(secret)

    totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
    code = totp.now

    assert user.verify_otp(code)
  end

  test "verify_otp rejects invalid code" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    user.enable_mfa!(secret)

    assert_not user.verify_otp("000000")
  end

  test "verify_otp prevents replay" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    user.enable_mfa!(secret)

    totp = ROTP::TOTP.new(secret, issuer: "Asthma Buddy")
    code = totp.now

    assert user.verify_otp(code)
    assert_not user.verify_otp(code)
  end

  test "verify_otp returns false for blank code" do
    user = users(:verified_user)
    user.enable_mfa!(ROTP::Base32.random)
    assert_not user.verify_otp("")
    assert_not user.verify_otp(nil)
  end

  # -- MFA: verify_recovery_code --

  test "verify_recovery_code consumes code on use" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    codes = user.enable_mfa!(secret)

    assert user.verify_recovery_code(codes.first)
    assert_equal 9, user.recovery_codes_remaining
    assert_not user.verify_recovery_code(codes.first)
  end

  test "verify_recovery_code normalizes input" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    codes = user.enable_mfa!(secret)

    # Add dashes and uppercase
    mangled = codes.first.upcase.insert(3, "-")
    assert user.verify_recovery_code(mangled)
  end

  # -- MFA: disable_mfa! --

  test "disable_mfa! clears all MFA fields" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    user.enable_mfa!(secret)
    user.disable_mfa!

    assert_nil user.otp_secret
    assert_not user.otp_required_for_login?
    assert_empty user.recovery_codes
  end

  # -- MFA: encryption at rest --

  test "otp_secret is encrypted at rest" do
    user = users(:verified_user)
    secret = ROTP::Base32.random
    user.enable_mfa!(secret)

    raw = User.connection.select_value("SELECT otp_secret FROM users WHERE id = #{user.id}")
    assert_not_equal secret, raw
  end

  # -- after_create_commit :notify_admin_of_signup --

  test "creating a user enqueues AdminMailer.new_signup via deliver_later" do
    Rails.application.credentials.stub(:admin_email, "admin@test.com") do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        User.create!(
          email_address: "trackme@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
      end
    end
  end
end
