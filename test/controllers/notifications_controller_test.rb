# frozen_string_literal: true

require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
    @alice_unread = notifications(:alice_low_stock)
    @alice_read   = notifications(:alice_read_old)
    @bob_notif    = notifications(:bob_notification)
  end

  # ---------------------------------------------------------------
  # GET /notifications (index)
  # ---------------------------------------------------------------

  test "index returns 200 for authenticated user" do
    get notifications_path
    assert_response :success
  end

  test "index lists only current user's notifications" do
    get notifications_path
    assert_response :success
    # Alice's notification body appears
    assert_select ".notification-body", text: /#{Regexp.escape(@alice_unread.body)}/
    # Bob's notification body does NOT appear
    assert_no_match @bob_notif.body, response.body
  end

  test "index redirects unauthenticated users to sign in" do
    sign_out
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "index returns JSON with notifications and unread_count" do
    get notifications_path, as: :json
    assert_response :success
    body = response.parsed_body
    assert body.key?("notifications")
    assert body.key?("unread_count")
    assert_kind_of Array, body["notifications"]
    assert_kind_of Integer, body["unread_count"]
  end

  # ---------------------------------------------------------------
  # PATCH /notifications/:id/mark_read
  # ---------------------------------------------------------------

  test "mark_read marks notification as read" do
    assert_not @alice_unread.read
    patch mark_read_notification_path(@alice_unread),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert @alice_unread.reload.read
  end

  test "mark_read returns Turbo Stream response" do
    patch mark_read_notification_path(@alice_unread),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "mark_read returns 404 for another user's notification" do
    patch mark_read_notification_path(@bob_notif),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :not_found
  end

  test "mark_read redirects unauthenticated users" do
    sign_out
    patch mark_read_notification_path(@alice_unread)
    assert_redirected_to new_session_path
  end

  test "mark_read returns JSON with read status and unread_count" do
    patch mark_read_notification_path(@alice_unread), as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal @alice_unread.id, body["id"]
    assert_equal true, body["read"]
    assert body.key?("unread_count")
  end

  # ---------------------------------------------------------------
  # POST /notifications/mark_all_read
  # ---------------------------------------------------------------

  test "mark_all_read marks all unread notifications as read" do
    unread_before = @user.notifications.unread.count
    assert unread_before > 0

    post mark_all_read_notifications_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success

    assert_equal 0, @user.notifications.unread.count
  end

  test "mark_all_read returns Turbo Stream response" do
    post mark_all_read_notifications_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "mark_all_read does not affect other users' notifications" do
    bob_read_before = @bob_notif.reload.read
    post mark_all_read_notifications_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_equal bob_read_before, @bob_notif.reload.read
  end

  test "mark_all_read redirects unauthenticated users" do
    sign_out
    post mark_all_read_notifications_path
    assert_redirected_to new_session_path
  end

  test "mark_all_read returns JSON with unread_count zero" do
    post mark_all_read_notifications_path, as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal 0, body["unread_count"]
  end
end

# Badge cache integration — swaps to MemoryStore so fetch/delete behave like production.
class BadgeCacheTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

  test "set_notification_badge_count writes to cache on first call and reads from cache on second call" do
    # First request — cache is cold; fetch block executes, value is stored.
    get dashboard_path
    assert_response :success
    cached_value = Rails.cache.read("unread_notifications/#{@user.id}")
    assert_not_nil cached_value, "Expected cache to be populated after first authenticated request"

    # Second request — cache is warm; value persists (block is not re-executed).
    get dashboard_path
    assert_response :success
    assert_equal cached_value, Rails.cache.read("unread_notifications/#{@user.id}"),
      "Expected cached value to remain the same on the second request"
  end
end

# Proves mark_all_read explicitly clears the badge cache so subsequent page
# loads do not resurrect the badge from a stale cached count.
class MarkAllReadCacheInvalidationTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    @user = users(:verified_user)
    sign_in_as @user
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    # Seed the cache with a non-zero count to simulate a warm cache from prior requests.
    Rails.cache.write("unread_notifications/#{@user.id}", 3)
  end

  teardown do
    Notification.where(user: @user).delete_all
    Rails.cache.clear
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

  test "mark_all_read deletes the badge cache key so the next request recomputes from DB" do
    # Cache is warm with stale count of 3.
    assert_equal 3, Rails.cache.read("unread_notifications/#{@user.id}")

    post mark_all_read_notifications_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success

    # Cache key must be gone — not 3, not 0.
    assert_nil Rails.cache.read("unread_notifications/#{@user.id}"),
      "Expected cache key to be deleted by mark_all_read, but it still exists"

    # Next authenticated request (e.g. dashboard) must re-populate cache from DB (which is 0).
    get dashboard_path
    assert_response :success
    assert_equal 0, Rails.cache.read("unread_notifications/#{@user.id}"),
      "Expected cache to be repopulated with 0 after mark_all_read cleared all notifications"
  end
end
