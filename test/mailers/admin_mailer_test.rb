# frozen_string_literal: true

require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  STUB_ADMIN_EMAIL = "admin@test.com"

  setup do
    @user = users(:verified_user)
  end

  test "new_signup renders with correct recipient and subject" do
    Rails.application.credentials.stub(:admin_email, STUB_ADMIN_EMAIL) do
      mail = AdminMailer.new_signup(@user)
      assert_equal [ STUB_ADMIN_EMAIL ], mail.to
      assert_match "New signup", mail.subject
      assert_match @user.email_address, mail.subject
    end
  end

  test "new_signup HTML body contains user email" do
    Rails.application.credentials.stub(:admin_email, STUB_ADMIN_EMAIL) do
      mail = AdminMailer.new_signup(@user)
      assert_match @user.email_address, mail.body.encoded
    end
  end
end
