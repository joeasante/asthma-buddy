# frozen_string_literal: true
require "test_helper"

class SymptomLogTest < ActiveSupport::TestCase
  def valid_attributes
    {
      user: users(:verified_user),
      symptom_type: :wheezing,
      severity: :mild,
      recorded_at: Time.current
    }
  end

  test "valid with all required attributes" do
    log = SymptomLog.new(valid_attributes)
    assert log.valid?, log.errors.full_messages.inspect
  end

  test "invalid without symptom_type" do
    log = SymptomLog.new(valid_attributes.except(:symptom_type))
    assert_not log.valid?
    assert log.errors[:symptom_type].any?
  end

  test "invalid without severity" do
    log = SymptomLog.new(valid_attributes.except(:severity))
    assert_not log.valid?
    assert log.errors[:severity].any?
  end

  test "invalid without recorded_at" do
    log = SymptomLog.new(valid_attributes.except(:recorded_at))
    assert_not log.valid?
    assert_includes log.errors[:recorded_at], "can't be blank"
  end

  test "invalid without user" do
    log = SymptomLog.new(valid_attributes.except(:user))
    assert_not log.valid?
  end

  test "symptom_types returns all four types" do
    assert_equal 4, SymptomLog.symptom_types.size
    assert SymptomLog.symptom_types.key?("wheezing")
    assert SymptomLog.symptom_types.key?("coughing")
    assert SymptomLog.symptom_types.key?("shortness_of_breath")
    assert SymptomLog.symptom_types.key?("chest_tightness")
  end

  test "severities returns all three levels" do
    assert_equal 3, SymptomLog.severities.size
    assert SymptomLog.severities.key?("mild")
    assert SymptomLog.severities.key?("moderate")
    assert SymptomLog.severities.key?("severe")
  end

  test "notes can store rich text" do
    log = SymptomLog.create!(valid_attributes)
    log.notes = "<p>Triggered by cold air</p>"
    log.save!
    assert_equal "Triggered by cold air", log.notes.to_plain_text.strip
  end

  test "chronological scope orders by recorded_at descending" do
    older = SymptomLog.create!(valid_attributes.merge(recorded_at: 3.hours.ago))
    newer = SymptomLog.create!(valid_attributes.merge(recorded_at: 1.hour.ago))
    results = SymptomLog.where(id: [older.id, newer.id]).chronological
    assert_equal newer.id, results.first.id
  end
end
