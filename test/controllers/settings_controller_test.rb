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
