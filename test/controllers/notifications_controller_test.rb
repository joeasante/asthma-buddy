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
