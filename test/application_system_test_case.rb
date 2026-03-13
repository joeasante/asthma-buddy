# frozen_string_literal: true

require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def sign_in_as(user, password: "password123")
    visit new_session_url
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: password
    click_button "Sign in"
    assert_current_path dashboard_url, wait: 15
  end

  # Sign in by setting a signed cookie pointing at a fixture session.
  # Unlike form-based sign-in, the session record already exists in fixtures and
  # is re-inserted (with the same deterministic ID) on every fixture reload, so
  # concurrent fixture reloads from other test classes cannot invalidate it.
  def sign_in_as_fixture(fixture_name)
    session_record = sessions(fixture_name)
    visit test_sign_in_url(session_id: session_record.id)
  end
end
