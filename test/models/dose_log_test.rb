# frozen_string_literal: true

require "test_helper"

class DoseLogTest < ActiveSupport::TestCase
  def setup
    @user       = users(:verified_user)
    @medication = medications(:alice_reliever)
  end

  def valid_attributes
    {
      user:        @user,
      medication:  @medication,
      puffs:       2,
      recorded_at: Time.current
    }
  end

  # Persistence

  test "valid dose log saves with all required fields" do
    log = DoseLog.new(valid_attributes)
    assert log.save, log.errors.full_messages.inspect
  end

  # Validations

  test "invalid without puffs" do
    log = DoseLog.new(valid_attributes.except(:puffs))
    assert_not log.valid?
    assert log.errors[:puffs].any?
  end

  test "invalid when puffs is zero" do
    log = DoseLog.new(valid_attributes.merge(puffs: 0))
    assert_not log.valid?
    assert log.errors[:puffs].any?
  end

  test "invalid when puffs is negative" do
    log = DoseLog.new(valid_attributes.merge(puffs: -1))
    assert_not log.valid?
    assert log.errors[:puffs].any?
  end

  test "invalid when puffs is not an integer" do
    log = DoseLog.new(valid_attributes.merge(puffs: 1.5))
    assert_not log.valid?
    assert log.errors[:puffs].any?
  end

  test "invalid without recorded_at" do
    log = DoseLog.new(valid_attributes.except(:recorded_at))
    assert_not log.valid?
    assert log.errors[:recorded_at].any?
  end

  test "invalid without user" do
    log = DoseLog.new(valid_attributes.except(:user))
    assert_not log.valid?
  end

  test "invalid without medication" do
    log = DoseLog.new(valid_attributes.except(:medication))
    assert_not log.valid?
  end

  # Associations

  test "belongs to user" do
    log = dose_logs(:alice_reliever_dose_1)
    assert_equal users(:verified_user), log.user
  end

  test "belongs to medication" do
    log = dose_logs(:alice_reliever_dose_1)
    assert_equal medications(:alice_reliever), log.medication
  end

  test "medication has_many dose_logs" do
    med = medications(:alice_reliever)
    assert_includes med.dose_logs, dose_logs(:alice_reliever_dose_1)
    assert_includes med.dose_logs, dose_logs(:alice_reliever_dose_2)
  end

  test "user has_many dose_logs" do
    assert_includes @user.dose_logs, dose_logs(:alice_reliever_dose_1)
  end

  # Scope

  test "chronological scope orders by recorded_at descending" do
    older = DoseLog.create!(valid_attributes.merge(recorded_at: 3.hours.ago))
    newer = DoseLog.create!(valid_attributes.merge(recorded_at: 1.hour.ago))
    results = DoseLog.where(id: [ older.id, newer.id ]).chronological
    assert_equal newer.id, results.first.id
  end

  # GINA band classification

  test "gina_band returns :controlled for uses below review threshold" do
    assert_equal :controlled, DoseLog.gina_band(0)
    assert_equal :controlled, DoseLog.gina_band(DoseLog::GINA_REVIEW_THRESHOLD - 1)
  end

  test "gina_band returns :review for uses at review threshold but below urgent threshold" do
    assert_equal :review, DoseLog.gina_band(DoseLog::GINA_REVIEW_THRESHOLD)
    assert_equal :review, DoseLog.gina_band(DoseLog::GINA_URGENT_THRESHOLD - 1)
  end

  test "gina_band returns :urgent for uses at or above urgent threshold" do
    assert_equal :urgent, DoseLog.gina_band(DoseLog::GINA_URGENT_THRESHOLD)
    assert_equal :urgent, DoseLog.gina_band(DoseLog::GINA_URGENT_THRESHOLD + 5)
  end

  test "GINA_REVIEW_THRESHOLD constant is defined on model" do
    assert_equal 3, DoseLog::GINA_REVIEW_THRESHOLD
  end

  test "GINA_URGENT_THRESHOLD constant is defined on model" do
    assert_equal 6, DoseLog::GINA_URGENT_THRESHOLD
  end

  # Cascade deletion

  test "dose log is destroyed when medication is destroyed" do
    log = DoseLog.create!(valid_attributes)
    @medication.destroy
    assert_not DoseLog.exists?(log.id)
  end
end
