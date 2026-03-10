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

  test "valid with known triggers" do
    log = SymptomLog.new(valid_attributes.merge(triggers: [ "exercise", "cold_air" ]))
    assert log.valid?, log.errors.full_messages.inspect
  end

  test "invalid with unknown trigger values" do
    log = SymptomLog.new(valid_attributes.merge(triggers: [ "exercise", "unknown_trigger" ]))
    assert_not log.valid?
    assert log.errors[:triggers].any?
  end

  test "valid with empty triggers array" do
    log = SymptomLog.new(valid_attributes.merge(triggers: []))
    assert log.valid?, log.errors.full_messages.inspect
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
    results = SymptomLog.where(id: [ older.id, newer.id ]).chronological
    assert_equal newer.id, results.first.id
  end

  # in_date_range scope

  test "in_date_range returns entries within start and end bounds" do
    alice = users(:verified_user)
    result = alice.symptom_logs.in_date_range(7.days.ago, Date.current)
    assert_includes result, symptom_logs(:alice_severe_recent)
    assert_includes result, symptom_logs(:alice_mild_week)
    assert_not_includes result, symptom_logs(:alice_coughing_old)
  end

  test "in_date_range with nil start returns from beginning of time" do
    alice = users(:verified_user)
    result = alice.symptom_logs.in_date_range(nil, Date.current)
    assert_includes result, symptom_logs(:alice_coughing_old)
  end

  test "in_date_range with nil end returns through present" do
    alice = users(:verified_user)
    result = alice.symptom_logs.in_date_range(7.days.ago, nil)
    assert_includes result, symptom_logs(:alice_severe_recent)
  end

  # severity_counts

  test "severity_counts returns hash with counts per severity" do
    alice = users(:verified_user)
    counts = alice.symptom_logs.severity_counts
    # Alice has: 1 moderate (alice_wheezing) + 2 mild (alice_coughing_old, alice_mild_week) + 1 severe (alice_severe_recent)
    assert_equal 2, counts[:mild]
    assert_equal 1, counts[:moderate]
    assert_equal 1, counts[:severe]
  end

  test "severity_counts with filtered relation returns counts for that range only" do
    alice = users(:verified_user)
    counts = alice.symptom_logs.in_date_range(7.days.ago, nil).severity_counts
    # Within 7 days: alice_wheezing (moderate), alice_severe_recent (severe), alice_mild_week (mild)
    assert_equal 1, counts[:mild]
    assert_equal 1, counts[:moderate]
    assert_equal 1, counts[:severe]
  end

  # paginate

  test "paginate returns first items on page 1" do
    alice = users(:verified_user)
    records, total_pages, current_page = alice.symptom_logs.chronological.paginate(page: 1, per_page: 2)
    assert_equal 1, current_page
    assert_equal 2, total_pages    # 4 fixtures / 2 per_page = 2 pages
    assert_equal 2, records.count
  end

  test "paginate clamps page to valid range" do
    alice = users(:verified_user)
    _, total_pages, current_page = alice.symptom_logs.paginate(page: 999, per_page: 25)
    assert_equal 1, current_page   # only 4 fixtures, all fit on 1 page at 25/page
    assert_equal 1, total_pages
  end
end
