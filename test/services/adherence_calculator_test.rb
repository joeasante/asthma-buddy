require "test_helper"

class AdherenceCalculatorTest < ActiveSupport::TestCase
  setup do
    @user      = users(:verified_user)
    @preventer = medications(:alice_preventer)  # doses_per_day: 2
    @reliever  = medications(:alice_reliever)   # doses_per_day: nil
    @today     = Time.current.to_date
  end

  # 1. on_track: preventer with 2 logs today
  test "returns on_track when all scheduled doses are logged" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 9))
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 13))

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 2,         result.taken
    assert_equal 2,         result.scheduled
    assert_equal :on_track, result.status
  end

  # 2. missed (partial): preventer with 1 log today
  test "returns missed when fewer than scheduled doses are logged" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 9))

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 1,       result.taken
    assert_equal 2,       result.scheduled
    assert_equal :missed, result.status
  end

  # 3. missed (none): preventer with 0 logs today
  test "returns missed when no doses are logged for a scheduled medication" do
    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal 0,       result.taken
    assert_equal 2,       result.scheduled
    assert_equal :missed, result.status
  end

  # 4. no_schedule: reliever with no doses_per_day
  test "returns no_schedule for a medication without doses_per_day" do
    DoseLog.create!(user: @user, medication: @reliever, puffs: 2, recorded_at: Time.current)

    result = AdherenceCalculator.call(@reliever, @today)

    assert_nil         result.scheduled
    assert_equal :no_schedule, result.status
  end

  # 5. before medication created_at
  test "returns no_schedule for a date before the medication was created" do
    past_date = @preventer.created_at.to_date - 1.day

    result = AdherenceCalculator.call(@preventer, past_date)

    assert_equal 0,            result.taken
    assert_nil                 result.scheduled
    assert_equal :no_schedule, result.status
  end

  # 6. exact boundary: taken == scheduled => on_track, taken == scheduled - 1 => missed
  test "returns on_track exactly when taken equals scheduled" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 9))
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 13))

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal :on_track, result.status
  end

  test "returns missed when taken is one below scheduled" do
    DoseLog.create!(user: @user, medication: @preventer, puffs: 2, recorded_at: Time.current.change(hour: 9))

    result = AdherenceCalculator.call(@preventer, @today)

    assert_equal :missed, result.status
  end
end
