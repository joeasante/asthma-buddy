# frozen_string_literal: true

require "test_helper"

class MedicationTest < ActiveSupport::TestCase
  def setup
    @user = users(:verified_user)
  end

  def valid_attributes
    {
      user: @user,
      name: "Ventolin",
      medication_type: :reliever,
      standard_dose_puffs: 2,
      starting_dose_count: 200
    }
  end

  # Persistence

  test "valid medication saves with required fields only" do
    med = Medication.new(valid_attributes)
    assert med.save, med.errors.full_messages.inspect
  end

  test "valid medication saves with all optional fields" do
    med = Medication.new(
      valid_attributes.merge(
        medication_type: :preventer,
        sick_day_dose_puffs: 4,
        doses_per_day: 2
      )
    )
    assert med.save, med.errors.full_messages.inspect
  end

  # Enum

  test "medication_type enum accepts all four values" do
    %i[reliever preventer combination other].each do |type|
      med = Medication.new(valid_attributes.merge(medication_type: type))
      assert med.valid?, "Expected #{type} to be valid: #{med.errors.full_messages}"
    end
  end

  test "medication_type enum rejects unknown value" do
    med = Medication.new(valid_attributes.merge(medication_type: :unknown))
    assert_not med.valid?
    assert med.errors[:medication_type].any?
  end

  # Validations — required fields

  test "invalid without name" do
    med = Medication.new(valid_attributes.except(:name))
    assert_not med.valid?
    assert med.errors[:name].any?
  end

  test "invalid without medication_type" do
    med = Medication.new(valid_attributes.except(:medication_type))
    assert_not med.valid?
    assert med.errors[:medication_type].any?
  end

  test "invalid without standard_dose_puffs" do
    med = Medication.new(valid_attributes.except(:standard_dose_puffs))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "invalid without starting_dose_count" do
    med = Medication.new(valid_attributes.except(:starting_dose_count))
    assert_not med.valid?
    assert med.errors[:starting_dose_count].any?
  end

  test "invalid without user" do
    med = Medication.new(valid_attributes.except(:user))
    assert_not med.valid?
  end

  # Validations — numerics

  test "invalid when standard_dose_puffs is zero" do
    med = Medication.new(valid_attributes.merge(standard_dose_puffs: 0))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "invalid when standard_dose_puffs is negative" do
    med = Medication.new(valid_attributes.merge(standard_dose_puffs: -1))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "valid when starting_dose_count is zero" do
    med = Medication.new(valid_attributes.merge(starting_dose_count: 0))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "invalid when starting_dose_count is negative" do
    med = Medication.new(valid_attributes.merge(starting_dose_count: -1))
    assert_not med.valid?
    assert med.errors[:starting_dose_count].any?
  end

  test "invalid when sick_day_dose_puffs is zero" do
    med = Medication.new(valid_attributes.merge(sick_day_dose_puffs: 0))
    assert_not med.valid?
    assert med.errors[:sick_day_dose_puffs].any?
  end

  test "valid when sick_day_dose_puffs is nil" do
    med = Medication.new(valid_attributes.merge(sick_day_dose_puffs: nil))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "valid when doses_per_day is nil" do
    med = Medication.new(valid_attributes.merge(doses_per_day: nil))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "invalid when doses_per_day is zero" do
    med = Medication.new(valid_attributes.merge(doses_per_day: 0))
    assert_not med.valid?
    assert med.errors[:doses_per_day].any?
  end

  # Association

  test "belongs to user" do
    med = medications(:alice_reliever)
    assert_equal users(:verified_user), med.user
  end

  # Scope

  test "chronological scope orders by created_at descending" do
    assert_equal @user.medications.order(created_at: :desc).to_a,
                 @user.medications.chronological.to_a
  end

  # remaining_doses

  test "remaining_doses returns starting_dose_count when no dose logs exist" do
    med = medications(:alice_combination)   # combination has no dose logs in fixtures
    assert_equal med.starting_dose_count, med.remaining_doses
  end

  test "remaining_doses subtracts all logged puffs" do
    med = medications(:alice_reliever)
    # alice_reliever_dose_1 (2) + alice_reliever_dose_2 (2) = 4
    # alice_reliever_weekly_3w_1..3w_4 (4 × 2 = 8)
    # alice_reliever_weekly_5w_1..5w_7 (7 × 2 = 14)
    # total = 26 puffs
    expected = med.starting_dose_count - 26
    assert_equal expected, med.remaining_doses
  end

  test "remaining_doses counts only logs for this medication" do
    med = medications(:alice_preventer)
    # alice_preventer has alice_preventer_dose_1 (2 puffs) — reliever logs should not be counted
    expected = med.starting_dose_count - 2
    assert_equal expected, med.remaining_doses
  end

  test "remaining_doses can return zero when all doses are logged" do
    med  = Medication.create!(
      user: @user, name: "Empty", medication_type: :other,
      standard_dose_puffs: 2, starting_dose_count: 2
    )
    DoseLog.create!(user: @user, medication: med, puffs: 2, recorded_at: Time.current)
    assert_equal 0, med.remaining_doses
  end

  test "remaining_doses can go negative when more puffs are logged than starting count" do
    med = Medication.create!(
      user: @user, name: "Overused", medication_type: :other,
      standard_dose_puffs: 2, starting_dose_count: 2
    )
    DoseLog.create!(user: @user, medication: med, puffs: 4, recorded_at: Time.current)
    assert_equal(-2, med.remaining_doses)
  end

  # days_of_supply_remaining

  test "days_of_supply_remaining returns nil when doses_per_day is nil" do
    med = medications(:alice_reliever)   # doses_per_day is nil
    assert_nil med.days_of_supply_remaining
  end

  test "days_of_supply_remaining returns nil when doses_per_day is zero" do
    # Should not happen via validations but defensive test
    med = Medication.new(
      user: @user, name: "Bad", medication_type: :other,
      standard_dose_puffs: 2, starting_dose_count: 100
    )
    med.instance_variable_set(:@doses_per_day_raw, 0)
    # Use direct attribute write to bypass validation — test the method's nil guard
    med.write_attribute(:doses_per_day, 0)
    assert_nil med.days_of_supply_remaining
  end

  test "days_of_supply_remaining divides remaining_doses by doses_per_day rounded to 1dp" do
    med = medications(:alice_preventer)
    # 120 starting - 2 logged puffs = 118 remaining; 118 / 2 = 59.0
    assert_equal 59.0, med.days_of_supply_remaining
  end

  test "days_of_supply_remaining rounds to one decimal place" do
    med = Medication.create!(
      user: @user, name: "Odd", medication_type: :preventer,
      standard_dose_puffs: 2, starting_dose_count: 100,
      doses_per_day: 3
    )
    # 100 / 3 = 33.333... → rounds to 33.3
    assert_equal 33.3, med.days_of_supply_remaining
  end

  test "days_of_supply_remaining returns 0.0 when no doses remain" do
    med = Medication.create!(
      user: @user, name: "Depleted", medication_type: :preventer,
      standard_dose_puffs: 2, starting_dose_count: 2,
      doses_per_day: 2
    )
    DoseLog.create!(user: @user, medication: med, puffs: 2, recorded_at: Time.current)
    assert_equal 0.0, med.days_of_supply_remaining
  end

  # refilled_at

  test "refilled_at is nil by default" do
    med = Medication.create!(valid_attributes)
    assert_nil med.refilled_at
  end

  test "refilled_at can be set and persisted" do
    med = Medication.create!(valid_attributes)
    time = Time.current
    med.update!(refilled_at: time)
    assert_in_delta time.to_f, med.reload.refilled_at.to_f, 1.0
  end

  # low_stock?

  test "low_stock? returns false when doses_per_day is nil (no schedule)" do
    med = medications(:alice_reliever)  # doses_per_day is nil
    assert_not med.low_stock?
  end

  test "low_stock? returns false when days_of_supply_remaining is exactly 14" do
    # 14 days * 2 doses/day = 28 doses remaining needed; starting_count=28, no logs
    med = Medication.create!(
      user: @user, name: "Boundary", medication_type: :preventer,
      standard_dose_puffs: 2, starting_dose_count: 28, doses_per_day: 2
    )
    assert_equal 14.0, med.days_of_supply_remaining
    assert_not med.low_stock?
  end

  test "low_stock? returns true when days_of_supply_remaining is below 14" do
    # 13 days * 2 doses/day = 26 doses remaining; starting=26, no logs
    med = Medication.create!(
      user: @user, name: "LowBoundary", medication_type: :preventer,
      standard_dose_puffs: 2, starting_dose_count: 26, doses_per_day: 2
    )
    assert_equal 13.0, med.days_of_supply_remaining
    assert med.low_stock?
  end

  test "low_stock? returns false when starting count is zero and doses_per_day is nil" do
    med = Medication.new(
      user: @user, name: "Empty reliever", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 0
    )
    assert_not med.low_stock?
  end

  test "low_stock? returns true after doses are logged and remaining drops below threshold" do
    med = Medication.create!(
      user: @user, name: "Running low", medication_type: :preventer,
      standard_dose_puffs: 2, starting_dose_count: 30, doses_per_day: 2
    )
    # Log 6 puffs — 24 remaining / 2 per day = 12 days → low stock
    DoseLog.create!(user: @user, medication: med, puffs: 6, recorded_at: Time.current)
    assert med.low_stock?
  end

  # --- Course scopes ---

  test "active_courses scope returns only course medications with ends_on >= today" do
    active     = medications(:alice_active_course)
    archived   = medications(:alice_archived_course)
    non_course = medications(:alice_reliever)

    result = Medication.active_courses
    assert_includes result, active
    assert_not_includes result, archived
    assert_not_includes result, non_course
  end

  test "archived_courses scope returns only course medications with ends_on < today" do
    active     = medications(:alice_active_course)
    archived   = medications(:alice_archived_course)
    non_course = medications(:alice_reliever)

    result = Medication.archived_courses
    assert_includes result, archived
    assert_not_includes result, active
    assert_not_includes result, non_course
  end

  test "non_courses scope excludes all course medications" do
    active     = medications(:alice_active_course)
    archived   = medications(:alice_archived_course)
    non_course = medications(:alice_reliever)

    result = Medication.non_courses
    assert_includes result, non_course
    assert_not_includes result, active
    assert_not_includes result, archived
  end

  # --- Course validations ---

  test "course medication valid with starts_on and ends_on set" do
    med = Medication.new(
      user: @user, name: "Pred Course", medication_type: :other,
      standard_dose_puffs: 5, starting_dose_count: 40,
      course: true, starts_on: Date.today, ends_on: 7.days.from_now.to_date
    )
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "course medication invalid without starts_on" do
    med = Medication.new(
      user: @user, name: "Pred Course", medication_type: :other,
      standard_dose_puffs: 5, starting_dose_count: 40,
      course: true, starts_on: nil, ends_on: 7.days.from_now.to_date
    )
    assert_not med.valid?
    assert med.errors[:starts_on].any?
  end

  test "course medication invalid without ends_on" do
    med = Medication.new(
      user: @user, name: "Pred Course", medication_type: :other,
      standard_dose_puffs: 5, starting_dose_count: 40,
      course: true, starts_on: Date.today, ends_on: nil
    )
    assert_not med.valid?
    assert med.errors[:ends_on].any?
  end

  test "course medication invalid when ends_on is before starts_on" do
    med = Medication.new(
      user: @user, name: "Pred Course", medication_type: :other,
      standard_dose_puffs: 5, starting_dose_count: 40,
      course: true, starts_on: Date.today, ends_on: 1.day.ago.to_date
    )
    assert_not med.valid?
    assert med.errors[:ends_on].any?
  end

  test "course medication invalid when ends_on equals starts_on" do
    med = Medication.new(
      user: @user, name: "Pred Course", medication_type: :other,
      standard_dose_puffs: 5, starting_dose_count: 40,
      course: true, starts_on: Date.today, ends_on: Date.today
    )
    assert_not med.valid?
    assert med.errors[:ends_on].any?
  end

  test "non-course medication created with course dates does not persist starts_on or ends_on" do
    med = Medication.create!(
      user: @user, name: "Regular", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 200,
      course: false, starts_on: Date.today, ends_on: 7.days.from_now.to_date
    )
    assert_nil med.starts_on
    assert_nil med.ends_on
  end

  test "non-course medication does not require starts_on or ends_on" do
    med = Medication.new(
      user: @user, name: "Regular Med", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 200,
      course: false, starts_on: nil, ends_on: nil
    )
    assert med.valid?, med.errors.full_messages.inspect
  end

  # --- course_active? predicate ---

  test "course_active? returns true when course: true and ends_on >= today" do
    assert medications(:alice_active_course).course_active?
  end

  test "course_active? returns false when course: true and ends_on < today" do
    assert_not medications(:alice_archived_course).course_active?
  end

  test "course_active? returns false when course: false" do
    assert_not medications(:alice_reliever).course_active?
  end

  # --- low_stock? excludes active courses ---

  test "low_stock? returns false for an active course regardless of supply level" do
    # 10 units / 2 per day = 5 days — would normally be low stock
    med = Medication.create!(
      user: @user, name: "Active Course Low", medication_type: :other,
      standard_dose_puffs: 1, starting_dose_count: 10, doses_per_day: 2,
      course: true, starts_on: Date.today, ends_on: 5.days.from_now.to_date
    )
    assert_not med.low_stock?
  end

  test "low_stock? applies normally to archived courses" do
    # An archived course may still have supply math — we don't suppress the flag there
    med = Medication.create!(
      user: @user, name: "Archived Course Low", medication_type: :other,
      standard_dose_puffs: 1, starting_dose_count: 10, doses_per_day: 2,
      course: true, starts_on: 14.days.ago.to_date, ends_on: 1.day.ago.to_date
    )
    # 10 / 2 = 5 days < 14 — low_stock? is true for archived courses
    assert med.low_stock?
  end
end

class MedicationDashboardCacheTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = users(:verified_user)
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
    Medication.where(name: "Cache Test Med").delete_all
  end

  test "creating a medication invalidates the dashboard cache" do
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), "sentinel")
    Medication.create!(
      user: @user, name: "Cache Test Med", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 200
    )
    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end

  test "updating a medication invalidates the dashboard cache" do
    med = Medication.create!(
      user: @user, name: "Cache Test Med", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 200
    )
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), "sentinel")
    med.update!(name: "Cache Test Med Updated")
    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
    med.update!(name: "Cache Test Med")  # restore for teardown delete_all
  end

  test "destroying a medication invalidates the dashboard cache" do
    med = Medication.create!(
      user: @user, name: "Cache Test Med", medication_type: :reliever,
      standard_dose_puffs: 2, starting_dose_count: 200
    )
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), "sentinel")
    med.destroy!
    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end
end
