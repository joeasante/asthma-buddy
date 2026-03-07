# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as @user
  end

  # GET /settings
  test "show renders settings page" do
    get settings_path
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "show displays current personal best when one exists" do
    pb = personal_best_records(:alice_updated_personal_best)
    get settings_path
    assert_select "strong", /#{pb.value}/
  end

  test "show displays 'No personal best set' when none exists" do
    PersonalBestRecord.where(user: @user).delete_all
    get settings_path
    assert_select ".settings-pb-unset"
  end

  # POST /settings/personal_best
  test "update_personal_best creates a new record and redirects" do
    assert_difference "PersonalBestRecord.count", 1 do
      post settings_personal_best_path, params: {
        personal_best_record: { value: 550 }
      }
    end

    assert_redirected_to settings_path
    assert_match "550 L/min", flash[:notice]
    assert_equal 550, PersonalBestRecord.current_for(@user).value
  end

  test "update_personal_best with value below 100 renders errors" do
    assert_no_difference "PersonalBestRecord.count" do
      post settings_personal_best_path, params: {
        personal_best_record: { value: 50 }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
  end

  test "update_personal_best with value above 900 renders errors" do
    assert_no_difference "PersonalBestRecord.count" do
      post settings_personal_best_path, params: {
        personal_best_record: { value: 950 }
      }
    end

    assert_response :unprocessable_entity
  end

  test "update_personal_best with missing value renders errors" do
    assert_no_difference "PersonalBestRecord.count" do
      post settings_personal_best_path, params: {
        personal_best_record: { value: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  # JSON API
  test "show returns JSON with current personal best" do
    pb = personal_best_records(:alice_updated_personal_best)
    get settings_path, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal pb.value, body["current_personal_best"]["value"]
    assert_equal 100, body["valid_range"]["min"]
    assert_equal 900, body["valid_range"]["max"]
  end

  test "show returns JSON with null personal best when none exists" do
    PersonalBestRecord.where(user: @user).delete_all
    get settings_path, as: :json

    assert_response :success
    assert_nil JSON.parse(response.body)["current_personal_best"]
  end

  test "update_personal_best returns 201 JSON on success" do
    post settings_personal_best_path,
         params: { personal_best_record: { value: 550 } },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 550, body["value"]
  end

  test "update_personal_best returns 422 JSON on failure" do
    post settings_personal_best_path,
         params: { personal_best_record: { value: 50 } },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].any?
  end

  test "unauthenticated JSON show returns 401" do
    delete session_path
    get settings_path, as: :json
    assert_response :unauthorized
  end

  test "unauthenticated user is redirected from settings" do
    delete session_path
    get settings_path
    assert_redirected_to new_session_path
  end

  test "create always scopes personal best to authenticated user" do
    post settings_personal_best_path, params: {
      personal_best_record: { value: 500 }
    }
    assert_equal @user, PersonalBestRecord.last.user
  end
end
