# frozen_string_literal: true

require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  test "registration_open? returns true when value is true" do
    setting = site_settings(:registration_open)
    assert_equal "true", setting.value
    assert SiteSetting.registration_open?
  end

  test "registration_open? returns false when value is false" do
    site_settings(:registration_open).update!(value: "false")
    Rails.cache.delete("site_setting:registration_open")
    assert_not SiteSetting.registration_open?
  end

  test "toggle_registration! flips the value from true to false" do
    assert SiteSetting.registration_open?
    SiteSetting.toggle_registration!
    assert_not SiteSetting.registration_open?
  end

  test "toggle_registration! flips the value from false to true" do
    site_settings(:registration_open).update!(value: "false")
    Rails.cache.delete("site_setting:registration_open")
    assert_not SiteSetting.registration_open?
    SiteSetting.toggle_registration!
    assert SiteSetting.registration_open?
  end

  test "key uniqueness validation" do
    duplicate = SiteSetting.new(key: "registration_open", value: "false")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "key presence validation" do
    setting = SiteSetting.new(key: nil, value: "true")
    assert_not setting.valid?
    assert_includes setting.errors[:key], "can't be blank"
  end
end
