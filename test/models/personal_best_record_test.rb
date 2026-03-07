# frozen_string_literal: true
require "test_helper"

class PersonalBestRecordTest < ActiveSupport::TestCase
  def setup
    @user = users(:verified_user)
  end

  def valid_attributes
    {
      user: @user,
      value: 500,
      recorded_at: Time.current
    }
  end

  # Persistence

  test "valid record saves with value 100" do
    record = PersonalBestRecord.new(valid_attributes.merge(value: 100))
    assert record.valid?, record.errors.full_messages.inspect
    assert record.save
  end

  test "valid record saves with value 900" do
    record = PersonalBestRecord.new(valid_attributes.merge(value: 900))
    assert record.valid?, record.errors.full_messages.inspect
    assert record.save
  end

  # Validations

  test "validation error when value < 100" do
    record = PersonalBestRecord.new(valid_attributes.merge(value: 99))
    assert_not record.valid?
    assert record.errors[:value].any?
  end

  test "validation error when value > 900" do
    record = PersonalBestRecord.new(valid_attributes.merge(value: 901))
    assert_not record.valid?
    assert record.errors[:value].any?
  end

  test "validation error when value absent" do
    record = PersonalBestRecord.new(valid_attributes.except(:value))
    assert_not record.valid?
    assert record.errors[:value].any?
  end

  test "validation error without recorded_at" do
    record = PersonalBestRecord.new(valid_attributes.except(:recorded_at))
    assert_not record.valid?
    assert record.errors[:recorded_at].any?
  end

  test "invalid without user" do
    record = PersonalBestRecord.new(valid_attributes.except(:user))
    assert_not record.valid?
  end

  # current_for

  test "current_for returns the most recent record" do
    # alice has alice_personal_best (30 days ago) and alice_updated_personal_best (7 days ago)
    current = PersonalBestRecord.current_for(@user)
    assert_not_nil current
    assert_equal personal_best_records(:alice_updated_personal_best).id, current.id
  end

  test "current_for returns nil when no records exist" do
    # Create a new user with no personal best records
    new_user = User.create!(
      email_address: "newuser@example.com",
      password: "password123",
      email_verified_at: Time.current
    )
    assert_nil PersonalBestRecord.current_for(new_user)
  end
end
