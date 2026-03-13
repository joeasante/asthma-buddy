# frozen_string_literal: true

require "application_system_test_case"

class HomeTest < ApplicationSystemTestCase
  test "visiting the homepage" do
    visit root_url

    assert_selector "h1", text: "Breathe easier."
    assert_selector "header"
    assert_selector "nav[aria-label='Main navigation']"
    assert_selector "main#main-content"
  end
end
