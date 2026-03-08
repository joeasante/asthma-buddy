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
end
