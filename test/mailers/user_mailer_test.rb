require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_verification sends to correct address" do
    user = users(:unverified_user)
    mail = UserMailer.email_verification(user)

    assert_equal [ user.email_address ], mail.to
  end

  test "email_verification has correct subject" do
    user = users(:unverified_user)
    mail = UserMailer.email_verification(user)

    assert_equal "Verify your email address — Asthma Buddy", mail.subject
  end

  test "email_verification body contains verification URL with token" do
    user = users(:unverified_user)
    mail = UserMailer.email_verification(user)

    assert_match(/email_verification/, mail.body.encoded)
    # Token is embedded in path: /email_verification/<base64-encoded-token>
    assert_match(%r{/email_verification/[A-Za-z0-9+/=_\-]+}, mail.body.encoded)
  end
end
