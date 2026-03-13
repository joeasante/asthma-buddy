# frozen_string_literal: true

require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  # -------------------------------------------------------------------------
  # 1. Valid notification saves with all required fields
  # -------------------------------------------------------------------------
  test "valid notification saves with all required fields" do
    notification = Notification.new(
      user:              users(:verified_user),
      notification_type: :system,
      body:              "Test body"
    )
    assert notification.valid?, notification.errors.full_messages.inspect
    assert notification.save
  end

  # -------------------------------------------------------------------------
  # 2. notification_type presence validation
  # -------------------------------------------------------------------------
  test "notification_type is required" do
    notification = Notification.new(
      user:              users(:verified_user),
      body:              "Test body",
      read:              false
    )
    assert_not notification.valid?
    # validate: true adds "is not included in the list" when type is nil/blank
    assert notification.errors[:notification_type].any?
  end

  test "invalid notification_type produces validation error" do
    notification = Notification.new(
      user:              users(:verified_user),
      body:              "Test body",
      read:              false,
      notification_type: "completely_invalid_type"
    )
    # validate: true routes unknown values to validation errors rather than ArgumentError
    assert_not notification.valid?
    assert notification.errors[:notification_type].any?
  end

  # -------------------------------------------------------------------------
  # 3. body presence validation
  # -------------------------------------------------------------------------
  test "body is required" do
    notification = Notification.new(
      user:              users(:verified_user),
      notification_type: :low_stock,
      notifiable:        medications(:alice_preventer),
      read:              false
    )
    assert_not notification.valid?
    assert_includes notification.errors[:body], "can't be blank"
  end

  # -------------------------------------------------------------------------
  # 4. Notification.unread scope returns only read=false records
  # -------------------------------------------------------------------------
  test "unread scope returns only unread notifications" do
    unread = Notification.unread
    assert_includes unread, notifications(:alice_low_stock)
    assert_includes unread, notifications(:alice_missed_dose)
    assert_not_includes unread, notifications(:alice_read_old)
  end

  # -------------------------------------------------------------------------
  # 5. Notification.newest_first scope orders by created_at desc
  # -------------------------------------------------------------------------
  test "newest_first scope orders by created_at descending" do
    ordered = Notification.newest_first.to_a
    ordered.each_cons(2) do |a, b|
      assert a.created_at >= b.created_at, "Expected #{a.created_at} >= #{b.created_at}"
    end
  end

  # -------------------------------------------------------------------------
  # 6. Notification.pruneable scope
  # -------------------------------------------------------------------------
  test "pruneable scope returns read=true AND created_at older than 90 days" do
    pruneable = Notification.pruneable
    assert_includes pruneable, notifications(:alice_read_old)
  end

  test "pruneable scope does NOT return unread old records" do
    old_unread = Notification.create!(
      user:              users(:verified_user),
      notification_type: :system,
      body:              "Old unread",
      read:              false,
      created_at:        95.days.ago
    )
    assert_not_includes Notification.pruneable, old_unread
  end

  test "pruneable scope does NOT return recently read records" do
    recent_read = Notification.create!(
      user:              users(:verified_user),
      notification_type: :system,
      body:              "Recent read",
      read:              true,
      created_at:        1.day.ago
    )
    assert_not_includes Notification.pruneable, recent_read
  end

  # -------------------------------------------------------------------------
  # 7. create_low_stock_for creates notification when low_stock? and no unread exists
  # -------------------------------------------------------------------------
  test "create_low_stock_for creates notification for low-stock medication" do
    # Create a medication with only 10 days of supply remaining (< 14 threshold)
    # starting_dose_count=20, doses_per_day=2 → 10 days remaining
    medication = Medication.create!(
      user:               users(:verified_user),
      name:               "Low Stock Med",
      medication_type:    :preventer,
      standard_dose_puffs: 1,
      starting_dose_count: 20,
      doses_per_day:       2
    )
    assert medication.low_stock?, "Medication should be low_stock? for this test"

    assert_difference "Notification.count", 1 do
      Notification.create_low_stock_for(medication)
    end

    notification = Notification.last
    assert_equal "low_stock", notification.notification_type
    assert_equal medication, notification.notifiable
    assert_equal users(:verified_user), notification.user
    assert_not notification.read
  end

  # -------------------------------------------------------------------------
  # 8. create_low_stock_for is a no-op when medication is NOT low_stock?
  # -------------------------------------------------------------------------
  test "create_low_stock_for is a no-op when medication is not low_stock?" do
    # alice_preventer has 120 puffs, 2 doses/day × 2 puffs/dose = 30 days supply, well above 14-day threshold
    # but it has dose_logs in fixtures that may reduce supply, so create a fresh one
    medication = Medication.create!(
      user:                users(:verified_user),
      name:                "Well Stocked Med",
      medication_type:     :preventer,
      standard_dose_puffs: 1,
      starting_dose_count: 200,
      doses_per_day:       2
    )
    assert_not medication.low_stock?, "Medication should NOT be low_stock? for this test"

    assert_no_difference "Notification.count" do
      Notification.create_low_stock_for(medication)
    end
  end

  # -------------------------------------------------------------------------
  # 9. create_low_stock_for deduplication — no-op when any low_stock exists (read or unread)
  # -------------------------------------------------------------------------
  test "create_low_stock_for is a no-op when unread low_stock already exists" do
    medication = Medication.create!(
      user:                users(:verified_user),
      name:                "Dup Check Med",
      medication_type:     :preventer,
      standard_dose_puffs: 1,
      starting_dose_count: 20,
      doses_per_day:       2
    )
    assert medication.low_stock?

    # First call — creates notification
    Notification.create_low_stock_for(medication)

    # Second call — should be a no-op (unread low_stock already exists)
    assert_no_difference "Notification.count" do
      Notification.create_low_stock_for(medication)
    end
  end

  test "create_low_stock_for creates a new notification when existing low_stock notification is read" do
    medication = Medication.create!(
      user:                users(:verified_user),
      name:                "Already Acked Med",
      medication_type:     :preventer,
      standard_dose_puffs: 1,
      starting_dose_count: 20,
      doses_per_day:       2
    )
    assert medication.low_stock?

    # Pre-existing read notification (user already acknowledged this alert)
    Notification.create!(
      user:              users(:verified_user),
      notification_type: :low_stock,
      notifiable:        medication,
      body:              "Pre-existing read alert.",
      read:              true
    )

    # After a refill + re-stock event, a new notification should be created
    # even though a read notification already exists for this medication.
    assert_difference "Notification.count", 1 do
      Notification.create_low_stock_for(medication)
    end
  end
end

# Top-level class required so self.use_transactional_tests = false propagates correctly
# in the Rails 8 parallel test runner — nested classes inherit the parent's transaction
# wrapping and after_commit callbacks never fire.
class NotificationBadgeCacheTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    @user = users(:verified_user)
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
    Notification.where(body: [ "Cache invalidation test", "Updated body text" ]).delete_all
  end

  test "creating a notification deletes the badge cache for the owner" do
    Rails.cache.write(Notification.badge_cache_key(@user.id), 99)
    assert_equal 99, Rails.cache.read(Notification.badge_cache_key(@user.id))

    Notification.create!(
      user:              @user,
      notification_type: :system,
      body:              "Cache invalidation test"
    )

    assert_nil Rails.cache.read(Notification.badge_cache_key(@user.id))
  end

  test "marking a notification as read deletes the badge cache" do
    notification = notifications(:alice_low_stock)
    Rails.cache.write(Notification.badge_cache_key(@user.id), 99)
    assert_equal 99, Rails.cache.read(Notification.badge_cache_key(@user.id))

    notification.update!(read: true)

    assert_nil Rails.cache.read(Notification.badge_cache_key(@user.id))
  ensure
    notification&.update_columns(read: false)
  end

  test "updating a notification field other than read does not clear the badge cache" do
    notification = notifications(:alice_low_stock)
    original_body = notification.body
    Rails.cache.write(Notification.badge_cache_key(@user.id), 99)

    notification.update!(body: "Updated body text")

    assert_equal 99, Rails.cache.read(Notification.badge_cache_key(@user.id))
  ensure
    notification&.update_columns(body: original_body)
  end
end
