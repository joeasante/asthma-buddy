# frozen_string_literal: true

require "application_system_test_case"

class MedicationsSystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:verified_user)
    sign_in_as(@user)
  end

  # --- ADD COURSE FLOW ---

  test "user can add a temporary course medication" do
    visit new_settings_medication_url

    fill_in "Medication name", with: "Prednisolone 5mg"
    select "Other", from: "Type"
    fill_in "Standard dose (puffs)", with: "5"
    fill_in "Starting dose count", with: "40"

    # Check the course checkbox — Stimulus controller should show date fields
    check "This is a temporary course (e.g. prednisolone tablets)"

    # Date inputs in headless Chrome require .set() to avoid concatenation issues
    end_date = 7.days.from_now.to_date
    find("input[name='medication[starts_on]']").set(Date.today.strftime("%Y-%m-%d"))
    find("input[name='medication[ends_on]']").set(end_date.strftime("%Y-%m-%d"))

    click_button "Add medication"

    # Course badge text is rendered uppercase via CSS; use case-insensitive match
    within "#medications_list" do
      assert_text "Prednisolone 5mg"
      assert_text(/course/i)
      assert_text "Ends #{end_date.strftime("%-d %b %Y")}"
    end
  end

  test "course date fields are hidden when checkbox is unchecked" do
    visit new_settings_medication_url

    # Date fields should be hidden initially (checkbox unchecked)
    # Use visible: :hidden because the element has the [hidden] attribute
    assert_selector "[data-course-toggle-target='courseFields']", visible: :hidden

    # Checking the box reveals the date fields
    check "This is a temporary course (e.g. prednisolone tablets)"
    assert_no_selector "[data-course-toggle-target='courseFields']", visible: :hidden
    assert_selector "input[name='medication[starts_on]']"
    assert_selector "input[name='medication[ends_on]']"

    # Unchecking hides them again
    uncheck "This is a temporary course (e.g. prednisolone tablets)"
    assert_selector "[data-course-toggle-target='courseFields']", visible: :hidden
  end

  test "doses_per_day field is hidden when course checkbox is checked" do
    visit new_settings_medication_url

    # doses_per_day visible initially
    assert_no_selector "[data-course-toggle-target='dosesPerDayField']", visible: :hidden

    check "This is a temporary course (e.g. prednisolone tablets)"

    # doses_per_day hidden after checking
    assert_selector "[data-course-toggle-target='dosesPerDayField']", visible: :hidden
  end

  # --- ARCHIVED COURSE DISPLAY ---

  test "archived course appears in Past courses section and not in active list" do
    # alice_archived_course fixture has ends_on = yesterday
    archived = medications(:alice_archived_course)

    visit settings_medications_url

    # Must NOT appear in active medications_list
    within "#medications_list" do
      assert_no_text archived.name
    end

    # Must appear in past_courses_section
    assert_selector "#past_courses_section"

    # Open the disclosure to reveal archived courses
    within "#past_courses_section" do
      find("summary.past-courses-toggle").click
      assert_text archived.name
    end
  end

  test "past courses section is collapsed by default" do
    visit settings_medications_url

    # The <details> element for past courses should not have the 'open' attribute
    assert_selector ".past-courses-disclosure:not([open])"
  end

  test "past courses section shows count badge" do
    visit settings_medications_url

    within "#past_courses_section" do
      # Count badge text equals number of archived courses for this user
      # alice_archived_course is the only archived fixture
      assert_selector ".past-courses-count-badge", text: "1"
    end
  end

  test "past courses section is hidden entirely when no archived courses exist" do
    medications(:alice_archived_course).destroy
    visit settings_medications_url
    assert_no_selector "#past_courses_section"
  end

  test "archived course row has no Log dose button" do
    visit settings_medications_url

    # Open the past courses disclosure to inspect contents
    within "#past_courses_section" do
      find("summary.past-courses-toggle").click
      assert_no_text "Log dose"
    end
  end

  # --- DOSE LOGGING ON ACTIVE COURSE ---

  test "active course has Log dose button and logging a dose decrements remaining count" do
    active_course = medications(:alice_active_course)

    visit settings_medications_url

    within "#medications_list" do
      within "##{dom_id(active_course)}" do
        # Open the log dose panel
        find("details.med-log-details summary").click

        # Submit a dose
        fill_in "Puffs taken", with: active_course.standard_dose_puffs.to_s
        click_button "Log dose"
      end
    end

    # Remaining count should decrement (check in the remaining count container)
    expected_remaining = active_course.remaining_doses - active_course.standard_dose_puffs
    within "#remaining_count_#{dom_id(active_course)}" do
      assert_text "#{expected_remaining} doses"
    end
  end

  # --- ADHERENCE EXCLUSION (visual) ---

  test "active course does not appear in Preventers Today section on dashboard" do
    # Create a preventer-type course
    preventer_course = @user.medications.create!(
      name:                "Pred Course",
      medication_type:     :preventer,
      standard_dose_puffs: 2,
      starting_dose_count: 60,
      doses_per_day:       2,
      course:              true,
      starts_on:           Date.today,
      ends_on:             7.days.from_now.to_date
    )

    visit dashboard_url

    # Preventer adherence section should not mention the course medication
    if page.has_selector?(".adherence-card, [data-section='preventer-adherence']", wait: 2)
      within(".adherence-card, [data-section='preventer-adherence']") do
        assert_no_text "Pred Course"
      end
    end
    # If no adherence section at all (no other preventers), that's also acceptable

  ensure
    preventer_course&.destroy
  end
end
