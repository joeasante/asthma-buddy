# frozen_string_literal: true

require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the homepage" do
    visit root_url

    assert_selector "h1", text: "Asthma Buddy"
    assert_selector "header[role=banner]"
    assert_selector "nav[role=navigation]"
  end
end
