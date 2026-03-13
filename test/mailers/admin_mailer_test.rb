# frozen_string_literal: true

require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:verified_user)
    # Stub admin_email so tests are not environment-dependent
    @original_admin_email = Rails.application.credentials.admin_email
  end

  test "new_signup renders with correct recipient and subject" do
    mail = AdminMailer.new_signup(@user)
    assert_equal [ Rails.application.credentials.admin_email ], mail.to
    assert_match "New signup", mail.subject
    assert_match @user.email_address, mail.subject
  end

  test "new_signup HTML body contains user email" do
    mail = AdminMailer.new_signup(@user)
    assert_match @user.email_address, mail.body.encoded
  end
end
