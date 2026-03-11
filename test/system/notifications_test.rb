# frozen_string_literal: true

require "application_system_test_case"

class NotificationsTest < ApplicationSystemTestCase
  setup do
    @user = users(:verified_user)
    sign_in_as @user

    # Create unread notifications inline for system test isolation.
    # (fixtures alice_low_stock and alice_missed_dose also exist for this user,
    # but we create these explicitly so each test has a known baseline)
    @low_stock_notif = Notification.create!(
      user:              @user,
      notification_type: :low_stock,
      notifiable:        medications(:alice_preventer),
      body:              "Clenil Modulite is running low.",
      read:              false
    )

    @missed_dose_notif = Notification.create!(
      user:              @user,
      notification_type: :missed_dose,
      notifiable:        medications(:alice_preventer),
      body:              "You haven't logged your Clenil Modulite dose today.",
      read:              false
    )
  end

  # ---------------------------------------------------------------
  # Badge visibility
  # ---------------------------------------------------------------

  test "unread badge appears on nav bell when unread notifications exist" do
    visit dashboard_path
    # Both desktop nav bell and bottom nav alerts link carry data-unread-count > 0
    # when there are unread notifications for the current user
    assert_selector "[data-unread-count]:not([data-unread-count='0'])", wait: 5
  end

  test "nav bell badge data-unread-count is zero after marking all notifications read" do
    visit notifications_path
    click_button "Mark all read"
    # After Turbo Stream replaces nav-bell, data-unread-count on #nav-bell becomes 0
    assert_selector "#nav-bell[data-unread-count='0']", wait: 5
  end

  # ---------------------------------------------------------------
  # Mark single notification as read
  # ---------------------------------------------------------------

  test "mark single notification as read updates row inline without full page reload" do
    visit notifications_path

    # Unread notification body is visible with bold styling
    assert_selector ".notification-body--unread", text: /Clenil Modulite is running low/, wait: 5

    # Click mark read on the low_stock notification using its turbo frame ID
    within("##{dom_id(@low_stock_notif)}") do
      click_button "Mark read"
    end

    # The row should update in place — unread dot and bold body are gone for that notification
    assert_no_selector "##{dom_id(@low_stock_notif)} .notification-unread-dot", wait: 5
    assert_no_selector "##{dom_id(@low_stock_notif)} .notification-body--unread", wait: 5
  end

  # ---------------------------------------------------------------
  # Mark all read
  # ---------------------------------------------------------------

  test "mark all read updates all rows and removes unread indicators" do
    visit notifications_path

    # Multiple unread rows visible (inline creates + fixtures)
    assert_selector ".notification-row--unread", minimum: 2, wait: 5

    click_button "Mark all read"

    # All rows should now be read-styled (Turbo Stream replaces each row)
    assert_no_selector ".notification-row--unread", wait: 5
    assert_no_selector ".notification-unread-dot", wait: 5
  end

  # ---------------------------------------------------------------
  # Empty state
  # ---------------------------------------------------------------

  test "empty state 'You're all caught up.' shown when all notifications are read" do
    # Mark all notifications as read (including inline created + fixtures)
    @user.notifications.update_all(read: true)

    visit notifications_path

    # View renders notifications-all-read paragraph when all are read
    assert_text "You're all caught up.", wait: 5
  end

  test "empty state shown when no notifications exist at all" do
    @user.notifications.destroy_all

    visit notifications_path

    # View renders empty-state div when @notifications is empty
    assert_text "You're all caught up.", wait: 5
  end

  # ---------------------------------------------------------------
  # Regression: Medications still accessible from desktop header
  # ---------------------------------------------------------------

  test "Medications link remains in desktop header after bottom nav replacement" do
    visit dashboard_path
    # Medications link must still exist in the desktop header nav
    assert_selector "header a[href*='settings/medications']", wait: 5
  end
end
