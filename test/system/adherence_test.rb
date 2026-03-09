# frozen_string_literal: true

require "application_system_test_case"

class AdherenceTest < ApplicationSystemTestCase
  setup do
    @user = users(:verified_user)
    sign_in_as @user

    # Create a second preventer with doses_per_day so adherence section appears on dashboard
    # alice_preventer fixture (Clenil Modulite) already has doses_per_day: 2
  end

  # ── Dashboard adherence section ──

  test "dashboard shows adherence section for preventer with schedule" do
    visit dashboard_path
    assert_selector ".dash-adherence"
    within ".dash-adherence" do
      assert_text "Clenil Modulite"
    end
  end

  test "dashboard adherence shows correct taken/scheduled count" do
    # alice_preventer has no logs today in fixtures — expect 0 / 2
    visit dashboard_path
    within ".dash-adherence" do
      assert_text "0 / 2"
    end
  end

  test "dashboard adherence section links to history page" do
    visit dashboard_path
    within ".dash-adherence" do
      click_link "View history"
    end
    assert_current_path adherence_path
  end

  # ── Adherence history page ──

  test "adherence history page renders with 7-day grid by default" do
    visit adherence_path
    assert_selector "h1", text: "Preventer Adherence"
    assert_selector ".adherence-toggle-btn--active", text: "7 days"
    assert_selector ".adherence-grid"
    assert_selector ".adherence-cell", minimum: 7
  end

  test "switching to 30-day view shows 30 cells" do
    visit adherence_path
    click_link "30 days"
    assert_selector ".adherence-toggle-btn--active", text: "30 days"
    assert_selector ".adherence-cell", minimum: 30
  end

  test "days before medication was added show as no_schedule (grey), not missed (red)" do
    # Create a medication added today — all days before today should be :no_schedule
    new_med = Medication.create!(
      user: @user,
      name: "BrandNewPreventer",
      medication_type: :preventer,
      standard_dose_puffs: 2,
      starting_dose_count: 120,
      doses_per_day: 2
    )

    visit adherence_path(days: 7)
    within ".adherence-medication-section", text: "BrandNewPreventer" do
      # The medication was created today — the 6 days before today should all be grey (no_schedule)
      # Today itself should be red (missed, 0 taken) or on_track if logged
      # All cells except possibly today must be no_schedule
      assert_selector ".adherence-cell--no_schedule", minimum: 6
      assert_no_selector ".adherence-cell--missed", count: 7  # not all 7 should be red
    end

    new_med.destroy
  end

  test "on_track day shows green cell" do
    # Log 2 doses today for alice_preventer (doses_per_day: 2)
    preventer = medications(:alice_preventer)
    DoseLog.create!(user: @user, medication: preventer, puffs: 2, recorded_at: Time.current.change(hour: 8))
    DoseLog.create!(user: @user, medication: preventer, puffs: 2, recorded_at: Time.current.change(hour: 20))

    visit adherence_path
    within ".adherence-medication-section", text: "Clenil Modulite" do
      # Today's cell (last in the grid) should be on_track (green)
      assert_selector ".adherence-cell--on_track", minimum: 1
    end
  end
end
