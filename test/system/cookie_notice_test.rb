# frozen_string_literal: true

require "application_system_test_case"

class CookieNoticeTest < ApplicationSystemTestCase
  test "cookie notice appears on first visit" do
    visit root_path
    assert_selector ".cookie-notice", visible: true
  end

  test "cookie notice is dismissed and does not reappear after dismiss" do
    visit root_path
    assert_selector ".cookie-notice", visible: true

    # Click dismiss button
    find(".cookie-notice-dismiss").click

    # Banner should be gone (removed from DOM after CSS transition)
    assert_no_selector ".cookie-notice", wait: 3

    # Navigate to another page in the same session
    visit root_path

    # Banner should not reappear — session flag is set
    assert_no_selector ".cookie-notice"
  end
end
