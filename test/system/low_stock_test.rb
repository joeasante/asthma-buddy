# frozen_string_literal: true

require "application_system_test_case"

class LowStockTest < ApplicationSystemTestCase
  setup do
    @user = users(:verified_user)
    ActiveJob::Base.queue_adapter = :inline
    sign_in_as @user

    # Create a medication that is below the 14-day threshold:
    # 20 doses / 2 per day = 10 days → low_stock? is true
    @low_stock_med = Medication.create!(
      user: @user,
      name: "TestPreventer",
      medication_type: :preventer,
      standard_dose_puffs: 2,
      starting_dose_count: 20,
      doses_per_day: 2
    )
  end

  teardown do
    ActiveJob::Base.queue_adapter = :test
  end

  # ── Medication row ──

  test "low-stock badge appears on medication row when supply is below 14 days" do
    visit settings_medications_path
    within ".med-row", text: "TestPreventer" do
      assert_text "Low stock"
      assert_text "10.0 days"
    end
  end

  test "medication row without doses_per_day shows no low-stock badge" do
    # alice_reliever has no doses_per_day — should never show badge
    visit settings_medications_path
    within ".med-row", text: "Ventolin" do
      assert_no_text "Low stock"
      assert_no_text "days"
    end
  end

  # ── Dashboard ──

  test "dashboard Medications section appears when a medication is low on stock" do
    visit dashboard_path
    assert_selector ".dash-medications"
    within ".dash-medications" do
      assert_text "TestPreventer"
      assert_text "Low stock"
    end
  end

  test "dashboard Medications section is absent when no medications are low on stock" do
    # Destroy the low-stock medication so no low-stock medications exist
    @low_stock_med.destroy
    visit dashboard_path
    assert_no_selector ".dash-medications"
  end

  # ── Refill clears the badge ──

  test "refilling a medication with sufficient count removes the low-stock badge" do
    visit settings_medications_path

    within ".med-row", text: "TestPreventer" do
      assert_text "Low stock"

      # Open overflow menu, then refill details
      find("details.med-overflow summary").click
      find("details.med-refill-details summary").click

      # 60 doses / 2 per day = 30 days → not low stock
      fill_in "medication[starting_dose_count]", with: "60"
      click_button "Confirm refill"
    end

    # After Turbo Stream update, badge should be gone
    within ".med-row", text: "TestPreventer" do
      assert_no_text "Low stock"
      assert_text "30.0 days"
    end
  end

  test "after refill, dashboard Medications section hides the medication" do
    # First, refill via the model directly (not UI) to test dashboard update
    @low_stock_med.update!(starting_dose_count: 60, refilled_at: Time.current)

    visit dashboard_path
    # 30 days remaining — no longer low stock — section should be gone
    assert_no_selector ".dash-medications"
  end
end
