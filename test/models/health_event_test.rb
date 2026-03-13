# frozen_string_literal: true

require "test_helper"

class HealthEventTest < ActiveSupport::TestCase
  def valid_attributes
    {
      user: users(:verified_user),
      event_type: :gp_appointment,
      recorded_at: Time.current.change(sec: 0)
    }
  end

  # --- Validations ---

  test "valid with required attributes" do
    event = HealthEvent.new(valid_attributes)
    assert event.valid?, event.errors.full_messages.inspect
  end

  test "invalid without event_type" do
    event = HealthEvent.new(valid_attributes.except(:event_type))
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test "invalid with unrecognized event_type" do
    event = HealthEvent.new(valid_attributes.merge(event_type: "hacked"))
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test "invalid without recorded_at" do
    event = HealthEvent.new(valid_attributes.except(:recorded_at))
    assert_not event.valid?
    assert_includes event.errors[:recorded_at], "can't be blank"
  end

  test "invalid without user" do
    event = HealthEvent.new(valid_attributes.except(:user))
    assert_not event.valid?
  end

  test "invalid when ended_at is before recorded_at" do
    recorded = Time.current.change(sec: 0)
    event = HealthEvent.new(valid_attributes.merge(
      event_type: :illness,
      recorded_at: recorded,
      ended_at: recorded - 1.second
    ))
    assert_not event.valid?
    assert event.errors[:ended_at].any?
  end

  test "invalid when ended_at equals recorded_at" do
    recorded = Time.current.change(sec: 0)
    event = HealthEvent.new(valid_attributes.merge(
      event_type: :illness,
      recorded_at: recorded,
      ended_at: recorded
    ))
    assert_not event.valid?
    assert event.errors[:ended_at].any?
  end

  test "valid when ended_at is after recorded_at" do
    recorded = Time.current.change(sec: 0)
    event = HealthEvent.new(valid_attributes.merge(
      event_type: :illness,
      recorded_at: recorded,
      ended_at: recorded + 1.minute
    ))
    assert event.valid?, event.errors.full_messages.inspect
  end

  test "valid with ended_at nil (ongoing)" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :illness, ended_at: nil))
    assert event.valid?, event.errors.full_messages.inspect
  end

  # --- Temporal bounds ---

  test "invalid when recorded_at is in the future" do
    event = HealthEvent.new(valid_attributes.merge(recorded_at: 1.day.from_now))
    assert_not event.valid?
    assert_includes event.errors[:recorded_at], "cannot be in the future"
  end

  test "invalid when recorded_at is before 1900" do
    event = HealthEvent.new(valid_attributes.merge(recorded_at: Date.new(1899, 12, 31).to_time))
    assert_not event.valid?
    assert_includes event.errors[:recorded_at], "is too far in the past"
  end

  test "invalid when ended_at is in the future" do
    event = HealthEvent.new(valid_attributes.merge(
      event_type: :illness,
      ended_at: 1.year.from_now
    ))
    assert_not event.valid?
    assert_includes event.errors[:ended_at], "cannot be in the future"
  end

  # --- Helpers ---

  test "point_in_time? returns true for gp_appointment" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :gp_appointment))
    assert event.point_in_time?
  end

  test "point_in_time? returns true for medication_change" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :medication_change))
    assert event.point_in_time?
  end

  test "point_in_time? returns false for illness" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :illness))
    assert_not event.point_in_time?
  end

  test "point_in_time? returns false for hospital_visit" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :hospital_visit))
    assert_not event.point_in_time?
  end

  test "point_in_time? returns false for other" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :other))
    assert_not event.point_in_time?
  end

  test "ongoing? returns true when not point_in_time and ended_at is nil" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :illness, ended_at: nil))
    assert event.ongoing?
  end

  test "ongoing? returns false when ended_at is present" do
    recorded = 20.days.ago
    event = HealthEvent.new(valid_attributes.merge(
      event_type: :illness,
      recorded_at: recorded,
      ended_at: recorded + 5.days
    ))
    assert_not event.ongoing?
  end

  test "ongoing? returns false for point_in_time type even with nil ended_at" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :gp_appointment, ended_at: nil))
    assert_not event.ongoing?
  end

  test "chart_label returns short label for chart markers" do
    assert_equal "Hosp", HealthEvent.new(valid_attributes.merge(event_type: :hospital_visit)).chart_label
    assert_equal "GP",   HealthEvent.new(valid_attributes.merge(event_type: :gp_appointment)).chart_label
    assert_equal "Rx",   HealthEvent.new(valid_attributes.merge(event_type: :medication_change)).chart_label
  end

  test "event_type_label returns human label from TYPE_LABELS" do
    event = HealthEvent.new(valid_attributes.merge(event_type: :hospital_visit))
    assert_equal "Hospital visit", event.event_type_label
  end

  test "event_type_css_modifier converts underscores to hyphens" do
    hospital = HealthEvent.new(valid_attributes.merge(event_type: :hospital_visit))
    assert_equal "hospital-visit", hospital.event_type_css_modifier

    gp = HealthEvent.new(valid_attributes.merge(event_type: :gp_appointment))
    assert_equal "gp-appointment", gp.event_type_css_modifier
  end

  # --- to_chart_marker ---

  test "to_chart_marker includes required base fields" do
    event = health_events(:alice_illness_resolved)
    marker = event.to_chart_marker
    assert marker[:date].present?
    assert marker[:type].present?
    assert marker[:label].present?
    assert marker[:css_modifier].present?
  end

  test "to_chart_marker includes end_date for duration events with ended_at" do
    event = health_events(:alice_illness_resolved)
    marker = event.to_chart_marker
    assert marker.key?(:end_date), "expected end_date key for duration event with ended_at"
  end

  test "to_chart_marker excludes end_date for duration events without ended_at" do
    event = health_events(:alice_illness_ongoing)
    marker = event.to_chart_marker
    assert_not marker.key?(:end_date)
  end

  test "to_chart_marker excludes end_date for point-in-time events even with ended_at" do
    event = HealthEvent.new(
      user: users(:verified_user),
      event_type: :gp_appointment,
      recorded_at: 3.days.ago,
      ended_at: 2.days.ago
    )
    marker = event.to_chart_marker
    assert_not marker.key?(:end_date), "point-in-time events must not have end_date"
  end

  # --- Scopes ---

  test "recent_first orders by recorded_at descending" do
    older = HealthEvent.create!(valid_attributes.merge(
      event_type: :illness,
      recorded_at: 10.days.ago
    ))
    newer = HealthEvent.create!(valid_attributes.merge(
      event_type: :illness,
      recorded_at: 2.days.ago
    ))
    results = HealthEvent.where(id: [ older.id, newer.id ]).recent_first
    assert_equal newer.id, results.first.id
  end
end

# Dashboard cache invalidation tests for HealthEvent
# Placed as a top-level class so self.use_transactional_tests = false takes effect.
# after_commit callbacks only fire when the transaction actually commits —
# wrapping in a rolled-back test transaction suppresses them.
class HealthEventDashboardCacheTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = users(:verified_user)
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
    # Clean up records created outside of a transaction
    HealthEvent.where(user: @user, event_type: "gp_appointment")
               .where("recorded_at >= ?", 1.minute.ago)
               .delete_all
    # Restore fixture state: alice_illness_ongoing must remain ended_at: nil
    HealthEvent.where(id: health_events(:alice_illness_ongoing).id).update_all(ended_at: nil)
  end

  test "creating a health event deletes the dashboard vars cache" do
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), { test: true })
    assert_not_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))

    HealthEvent.create!(user: @user, event_type: :gp_appointment, recorded_at: Time.current.change(sec: 0))

    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end

  test "updating a health event deletes the dashboard vars cache" do
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), { test: true })
    assert_not_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))

    event = health_events(:alice_illness_ongoing)
    event.update!(ended_at: Time.current)

    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end

  test "destroying a health event deletes the dashboard vars cache" do
    event = HealthEvent.create!(user: @user, event_type: :gp_appointment, recorded_at: Time.current.change(sec: 0))
    Rails.cache.write(DashboardVariables.dashboard_cache_key(@user.id), { test: true })
    assert_not_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))

    event.destroy

    assert_nil Rails.cache.read(DashboardVariables.dashboard_cache_key(@user.id))
  end
end
