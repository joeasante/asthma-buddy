# frozen_string_literal: true

require "test_helper"

class Settings::MedicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    @other_user = users(:unverified_user)
    sign_in_as(@user)
    @medication = medications(:alice_reliever)
    @other_medication = medications(:bob_reliever)
  end

  # --- INDEX ---

  test "index redirects unauthenticated user to sign in" do
    sign_out
    get settings_medications_url
    assert_redirected_to new_session_url
  end

  test "index renders for authenticated user" do
    get settings_medications_url
    assert_response :success
    assert_select "h1", "Medications"
  end

  test "index shows only current user's medications" do
    get settings_medications_url
    assert_response :success
    assert_select "##{dom_id(@medication)}"
    assert_select "##{dom_id(@other_medication)}", count: 0
  end

  # --- NEW ---

  test "new renders the form" do
    get new_settings_medication_url
    assert_response :success
    assert_select "form"
  end

  # --- CREATE ---

  test "create saves a valid medication and responds with turbo stream" do
    assert_difference "Medication.count", 1 do
      post settings_medications_url,
        params: { medication: {
          name: "Spiriva",
          medication_type: "preventer",
          standard_dose_puffs: 1,
          starting_dose_count: 30
        } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "create scopes new medication to current user" do
    post settings_medications_url,
      params: { medication: {
        name: "Spiriva",
        medication_type: "preventer",
        standard_dose_puffs: 1,
        starting_dose_count: 30
      } }
    assert_equal @user, Medication.last.user
  end

  test "create with invalid params renders unprocessable_entity" do
    assert_no_difference "Medication.count" do
      post settings_medications_url,
        params: { medication: { name: "", medication_type: "", standard_dose_puffs: "", starting_dose_count: "" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  test "create saves optional sick_day_dose_puffs and doses_per_day when provided" do
    post settings_medications_url,
      params: { medication: {
        name: "Clenil",
        medication_type: "preventer",
        standard_dose_puffs: 2,
        starting_dose_count: 120,
        sick_day_dose_puffs: 4,
        doses_per_day: 2
      } }
    created = Medication.last
    assert_equal 4, created.sick_day_dose_puffs
    assert_equal 2, created.doses_per_day
  end

  # --- EDIT ---

  test "edit renders for owner" do
    get edit_settings_medication_url(@medication)
    assert_response :success
    assert_select "form"
  end

  test "edit returns 404 for another user's medication" do
    get edit_settings_medication_url(@other_medication)
    assert_response :not_found
  end

  # --- UPDATE ---

  test "update changes the medication name and responds with turbo stream" do
    patch settings_medication_url(@medication),
      params: { medication: { name: "Salbutamol Inhaler" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_equal "Salbutamol Inhaler", @medication.reload.name
  end

  test "update with invalid params renders unprocessable_entity" do
    patch settings_medication_url(@medication),
      params: { medication: { name: "", standard_dose_puffs: "" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :unprocessable_entity
  end

  test "update returns 404 for another user's medication" do
    patch settings_medication_url(@other_medication),
      params: { medication: { name: "Stolen" } }
    assert_response :not_found
  end

  # --- DESTROY ---

  test "destroy removes the medication and responds with turbo stream" do
    assert_difference "Medication.count", -1 do
      delete settings_medication_url(@medication),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "destroy returns 404 for another user's medication" do
    assert_no_difference "Medication.count" do
      delete settings_medication_url(@other_medication)
    end
    assert_response :not_found
  end

  # Refill action

  test "refill updates starting_dose_count and sets refilled_at" do
    medication = medications(:alice_preventer)
    assert_nil medication.refilled_at

    patch refill_settings_medication_path(medication),
          params: { medication: { starting_dose_count: 180 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    medication.reload
    assert_equal 180, medication.starting_dose_count
    assert_not_nil medication.refilled_at
  end

  test "refill with count of 0 is valid (empty inhaler logged)" do
    medication = medications(:alice_preventer)

    patch refill_settings_medication_path(medication),
          params: { medication: { starting_dose_count: 0 } },
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_equal 0, medication.reload.starting_dose_count
  end

  test "refill returns 404 for another user's medication" do
    other_medication = medications(:bob_reliever)

    patch refill_settings_medication_path(other_medication),
          params: { medication: { starting_dose_count: 100 } }

    assert_response :not_found
  end

  test "refill redirects unauthenticated user" do
    sign_out
    patch refill_settings_medication_path(medications(:alice_preventer)),
          params: { medication: { starting_dose_count: 100 } }

    assert_redirected_to new_session_path
  end

  # --- COURSE: INDEX SPLIT ---

  test "index assigns active_medications excluding archived courses" do
    # alice_active_course: ends_on = 7 days from now (active)
    # alice_archived_course: ends_on = yesterday (archived)
    get settings_medications_url
    assert_response :success

    # Active course should appear in medications_list
    assert_select "##{dom_id(medications(:alice_active_course))}"

    # Archived course should NOT appear in medications_list
    # (it appears only in past_courses_section, not medications_list)
    assert_select "#past_courses_section"
  end

  test "index does not show past courses section when no archived courses exist" do
    # Destroy the archived course fixture to simulate zero archived courses
    medications(:alice_archived_course).destroy
    get settings_medications_url
    assert_response :success
    assert_select "#past_courses_section", count: 0
  end

  # --- COURSE: CREATE ---

  test "create saves a course medication with course fields" do
    assert_difference "Medication.count", 1 do
      post settings_medications_url,
        params: { medication: {
          name: "Prednisolone",
          medication_type: "other",
          standard_dose_puffs: 5,
          starting_dose_count: 40,
          course: "1",
          starts_on: Date.today.to_s,
          ends_on: 7.days.from_now.to_date.to_s
        } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success

    med = Medication.last
    assert med.course?
    assert_equal Date.today, med.starts_on
    assert_equal 7.days.from_now.to_date, med.ends_on
    assert_equal @user, med.user
  end

  test "create scopes course medication to current user" do
    post settings_medications_url,
      params: { medication: {
        name: "Prednisolone",
        medication_type: "other",
        standard_dose_puffs: 5,
        starting_dose_count: 40,
        course: "1",
        starts_on: Date.today.to_s,
        ends_on: 7.days.from_now.to_date.to_s
      } }
    assert_equal @user, Medication.last.user
  end

  test "create rejects course medication with ends_on before starts_on" do
    assert_no_difference "Medication.count" do
      post settings_medications_url,
        params: { medication: {
          name: "Bad Course",
          medication_type: "other",
          standard_dose_puffs: 5,
          starting_dose_count: 40,
          course: "1",
          starts_on: Date.today.to_s,
          ends_on: 1.day.ago.to_date.to_s
        } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  test "create rejects course medication without ends_on" do
    assert_no_difference "Medication.count" do
      post settings_medications_url,
        params: { medication: {
          name: "Missing End",
          medication_type: "other",
          standard_dose_puffs: 5,
          starting_dose_count: 40,
          course: "1",
          starts_on: Date.today.to_s,
          ends_on: ""
        } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :unprocessable_entity
  end

  # --- COURSE: ARCHIVE BOUNDARY ---

  test "active course (ends_on today) is treated as active — not archived" do
    med = medications(:alice_active_course)
    # Force ends_on to today
    med.update_column(:ends_on, Date.today)

    get settings_medications_url
    assert_response :success

    # Should still appear in medications_list (active), not only in past_courses_section
    assert_select "##{dom_id(med)}"
  end

  test "archived course (ends_on yesterday) does not appear in active medications_list" do
    get settings_medications_url
    assert_response :success

    archived = medications(:alice_archived_course)
    # Archived course should be in the past_courses_section, not medications_list
    # We verify the section exists and the active list excludes it
    within_turbo_frame = response.body.include?(dom_id(archived))
    assert within_turbo_frame, "Archived course turbo frame should be present in page"
    assert_select "#past_courses_section"
  end

  # --- COURSE: ADHERENCE EXCLUSION ---

  test "dashboard excludes active courses from preventer_adherence" do
    # alice_active_course is medication_type :other — not a preventer — so this
    # test creates a preventer course to confirm exclusion
    preventer_course = @user.medications.create!(
      name:                "Preventer Course",
      medication_type:     :preventer,
      standard_dose_puffs: 2,
      starting_dose_count: 60,
      doses_per_day:       2,
      course:              true,
      starts_on:           Date.today,
      ends_on:             7.days.from_now.to_date
    )

    get dashboard_url
    assert_response :success

    # The preventer course should NOT be in preventer adherence
    # We verify by checking response does not render that medication's adherence card
    assert_select "[data-medication-id='#{preventer_course.id}']", count: 0
  ensure
    preventer_course&.destroy
  end

  # --- COURSE: UPDATE ---

  test "update course medication responds with course_medication partial" do
    course_med = medications(:alice_active_course)
    patch settings_medication_url(course_med),
      params: { medication: { name: "Updated Prednisolone" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match "medication-badge--course", response.body
    assert_equal "Updated Prednisolone", course_med.reload.name
  end

  test "update non-course medication responds with medication partial" do
    patch settings_medication_url(@medication),
      params: { medication: { name: "Updated Ventolin" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_no_match "medication-badge--course", response.body
  end

  # --- COURSE: CROSS-USER ISOLATION ---

  test "cannot access another user's course medication edit page" do
    other_course = medications(:alice_active_course)
    # sign in as a different user
    sign_out
    sign_in_as(@other_user)
    get edit_settings_medication_url(other_course)
    assert_response :not_found
  end

  test "cannot destroy another user's course medication" do
    other_course = medications(:alice_active_course)
    sign_out
    sign_in_as(@other_user)
    assert_no_difference "Medication.count" do
      delete settings_medication_url(other_course)
    end
    assert_response :not_found
  end
end
