# frozen_string_literal: true
require "test_helper"

class PeakFlowReadingTest < ActiveSupport::TestCase
  def setup
    @user = users(:verified_user)
  end

  def valid_attributes
    {
      user:        @user,
      value:       400,
      recorded_at: Time.current,
      time_of_day: :morning
    }
  end

  # Persistence

  test "valid reading saves with a personal best present — zone assigned automatically" do
    # Personal best of 500 exists for verified_user (alice_personal_best fixture, 30 days ago)
    reading = PeakFlowReading.new(valid_attributes.merge(recorded_at: 1.day.ago))
    assert reading.save, reading.errors.full_messages.inspect
    assert_not_nil reading.zone
  end

  test "valid reading saves without a personal best — zone is nil" do
    # Record a reading before any personal best exists (fixtures have pb at 30 days ago)
    reading = PeakFlowReading.new(valid_attributes.merge(recorded_at: 90.days.ago))
    assert reading.save, reading.errors.full_messages.inspect
    assert_nil reading.zone
  end

  # compute_zone

  test "compute_zone returns :green when value >= 80% of personal best" do
    # personal best at 1.day.ago = alice_updated_personal_best (520, set 7 days ago)
    # 80% of 520 = 416; use 420 => green
    reading = PeakFlowReading.new(valid_attributes.merge(value: 420, recorded_at: 1.day.ago))
    assert_equal :green, reading.compute_zone
  end

  test "compute_zone returns :yellow when value is 50-79% of personal best" do
    # personal best at 1.day.ago = 520; 50% = 260, 79% = ~410; use 280 => yellow
    reading = PeakFlowReading.new(valid_attributes.merge(value: 280, recorded_at: 1.day.ago))
    assert_equal :yellow, reading.compute_zone
  end

  test "compute_zone returns :red when value < 50% of personal best" do
    # personal best at 1.day.ago = 520; 50% = 260; use 200 (38%) => red
    reading = PeakFlowReading.new(valid_attributes.merge(value: 200, recorded_at: 1.day.ago))
    assert_equal :red, reading.compute_zone
  end

  test "compute_zone returns nil when no personal best record exists before recording time" do
    # 90 days ago — no personal best exists yet (fixtures start at 30 days ago)
    reading = PeakFlowReading.new(valid_attributes.merge(recorded_at: 90.days.ago))
    assert_nil reading.compute_zone
  end

  # Validations

  test "invalid without value" do
    reading = PeakFlowReading.new(valid_attributes.except(:value))
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "invalid without recorded_at" do
    reading = PeakFlowReading.new(valid_attributes.except(:recorded_at))
    assert_not reading.valid?
    assert reading.errors[:recorded_at].any?
  end

  test "invalid when value is zero" do
    reading = PeakFlowReading.new(valid_attributes.merge(value: 0))
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "invalid when value is negative" do
    reading = PeakFlowReading.new(valid_attributes.merge(value: -10))
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "invalid when value is not an integer" do
    reading = PeakFlowReading.new(valid_attributes.merge(value: 3.5))
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "invalid when value exceeds 900" do
    reading = PeakFlowReading.new(valid_attributes.merge(value: 901))
    assert_not reading.valid?
    assert reading.errors[:value].any?
  end

  test "valid when value is exactly 900" do
    reading = PeakFlowReading.new(valid_attributes.merge(value: 900, recorded_at: 1.day.ago))
    assert reading.valid?, reading.errors.full_messages.inspect
  end

  test "invalid without user" do
    reading = PeakFlowReading.new(valid_attributes.except(:user))
    assert_not reading.valid?
  end

  # Scope

  test "chronological scope orders by recorded_at descending" do
    older = PeakFlowReading.create!(valid_attributes.merge(recorded_at: 3.hours.ago))
    newer = PeakFlowReading.create!(valid_attributes.merge(recorded_at: 1.hour.ago))
    results = PeakFlowReading.where(id: [ older.id, newer.id ]).chronological
    assert_equal newer.id, results.first.id
  end
end
