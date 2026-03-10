require "test_helper"

class AdherenceCalculatorTest < ActiveSupport::TestCase
  setup do
    @user      = users(:verified_user)
    @preventer = medications(:alice_preventer)  # doses_per_day: 2
    @reliever  = medications(:alice_reliever)   # doses_per_day: nil
    @today     = Time.current.to_date
    # Use 2 days ago — the dose_logs fixture only has a preventer dose on 1.day.ago,
    # so this date is clean for tests that control their own dose data.
    @past_date = @today - 2.days
  end

  # ── on_track ─────────────────────────────────────────────────────
  test "returns on_track when all scheduled doses are logged today" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @today.beginning_of_day + 8.hours)
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @today.beginning_of_day + 20.hours)

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 2,         result.taken
    assert_equal 2,         result.scheduled
    assert_equal :on_track, result.status
  end

  # ── partial / pending — today only ───────────────────────────────
  test "returns partial when some but not all doses are logged today" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @today.beginning_of_day + 8.hours)

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 1,        result.taken
    assert_equal 2,        result.scheduled
    assert_equal :partial, result.status
  end

  test "returns pending when no doses are logged yet today" do
    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 0,        result.taken
    assert_equal 2,        result.scheduled
    assert_equal :pending, result.status
  end

  # ── missed — past days only ───────────────────────────────────────
  test "returns missed for a past day with fewer than scheduled doses" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @past_date.beginning_of_day + 8.hours)

    result = AdherenceCalculator.call(@preventer, @past_date)

    assert_equal 1,       result.taken
    assert_equal 2,       result.scheduled
    assert_equal :missed, result.status
  end

  test "returns missed for a past day with no doses logged" do
    result = AdherenceCalculator.call(@preventer, @past_date)

    assert_equal 0,       result.taken
    assert_equal 2,       result.scheduled
    assert_equal :missed, result.status
  end

  test "returns on_track for a past day where all doses were logged" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @past_date.beginning_of_day + 8.hours)
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: @past_date.beginning_of_day + 20.hours)

    result = AdherenceCalculator.call(@preventer, @past_date)

    assert_equal :on_track, result.status
  end

  # ── no_schedule ───────────────────────────────────────────────────
  test "returns no_schedule for a medication without doses_per_day" do
    result = AdherenceCalculator.call(@reliever, @today)

    assert_nil result.scheduled
    assert_equal :no_schedule, result.status
  end

  test "returns no_schedule for a date before the medication was created" do
    past_date = @preventer.created_at.to_date - 1.day

    result = AdherenceCalculator.call(@preventer, past_date)

    assert_equal 0,            result.taken
    assert_nil                 result.scheduled
    assert_equal :no_schedule, result.status
  end

  # ── preloaded_logs shortcut ───────────────────────────────────────
  test "accepts preloaded_logs array and returns on_track when count matches scheduled" do
    # Two placeholder objects — only their count matters
    result = AdherenceCalculator.call(@preventer, @today, preloaded_logs: [ :a, :b ])

    assert_equal 2,         result.taken
    assert_equal :on_track, result.status
  end

  test "treats empty preloaded_logs array as zero doses taken on a past day" do
    result = AdherenceCalculator.call(@preventer, @past_date, preloaded_logs: [])

    assert_equal 0,       result.taken
    assert_equal :missed, result.status
  end
end
