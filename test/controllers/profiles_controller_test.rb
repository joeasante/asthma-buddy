# frozen_string_literal: true

require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:verified_user)
    sign_in_as(@user)
  end

  # ---------------------------------------------------------------------------
  # Unauthenticated access
  # ---------------------------------------------------------------------------

  test "unauthenticated GET /profile redirects to sign-in" do
    sign_out
    get profile_path
    assert_redirected_to new_session_path
  end

  test "unauthenticated PATCH /profile redirects to sign-in" do
    sign_out
    patch profile_path, params: { user: { full_name: "Eve" } }
    assert_redirected_to new_session_path
  end

  test "unauthenticated POST /profile/personal_best redirects to sign-in" do
    sign_out
    post profile_personal_best_path, params: { personal_best_record: { value: 450 } }
    assert_redirected_to new_session_path
  end

  # ---------------------------------------------------------------------------
  # show
  # ---------------------------------------------------------------------------

  test "GET /profile renders successfully" do
    get profile_path
    assert_response :ok
  end

  test "GET /profile returns JSON with id, full_name, date_of_birth, avatar_url" do
    get profile_path(format: :json)
    assert_response :ok
    json = response.parsed_body
    assert json.key?("id")
    assert json.key?("full_name")
    assert json.key?("date_of_birth")
    assert json.key?("avatar_url")
    assert_equal @user.id, json["id"]
  end

  test "unauthenticated GET /profile JSON returns 401" do
    sign_out
    get profile_path(format: :json)
    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # update — name / date_of_birth
  # ---------------------------------------------------------------------------

  test "PATCH /profile with valid name and date_of_birth updates and redirects" do
    patch profile_path, params: { user: { full_name: "Alice Smith", date_of_birth: "1990-06-15" } }
    assert_redirected_to profile_path
    follow_redirect!
    assert_equal "Profile updated.", flash[:notice]
    @user.reload
    assert_equal "Alice Smith", @user.full_name
    assert_equal Date.new(1990, 6, 15), @user.date_of_birth
  end

  # ---------------------------------------------------------------------------
  # update — password change
  # ---------------------------------------------------------------------------

  test "PATCH /profile with wrong current_password fails and renders show" do
    patch profile_path, params: {
      user: {
        current_password: "wrong-password",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_response :unprocessable_entity
    assert_select "body"  # still renders a page (show template)
    # Ensure the password was NOT changed
    @user.reload
    assert @user.authenticate("password123"), "original password should still work"
  end

  test "PATCH /profile with correct current_password and new password succeeds" do
    patch profile_path, params: {
      user: {
        current_password: "password123",
        password: "newpassword456",
        password_confirmation: "newpassword456"
      }
    }
    assert_redirected_to profile_path
    follow_redirect!
    assert_equal "Profile updated.", flash[:notice]
    @user.reload
    assert @user.authenticate("newpassword456"), "new password should authenticate"
  end

  # ---------------------------------------------------------------------------
  # update — JSON format
  # ---------------------------------------------------------------------------

  test "PATCH /profile returns JSON when format.json is requested" do
    patch profile_path(format: :json), params: {
      user: { full_name: "Alice JSON", date_of_birth: "1985-03-20" }
    }
    assert_response :ok
    json = response.parsed_body
    assert_equal "Alice JSON", json["full_name"]
    assert_equal @user.id, json["id"]
  end

  test "PATCH /profile returns JSON errors when current_password is wrong" do
    patch profile_path(format: :json), params: {
      user: {
        current_password: "wrong",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
    }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["errors"].any? { |e| e.include?("current password") || e.downcase.include?("incorrect") },
           "Expected a current_password error, got: #{json['errors'].inspect}"
  end

  # ---------------------------------------------------------------------------
  # update_personal_best
  # ---------------------------------------------------------------------------

  test "POST /profile/personal_best saves record and redirects" do
    assert_difference -> { @user.personal_best_records.count }, +1 do
      post profile_personal_best_path, params: { personal_best_record: { value: 520 } }
    end
    assert_redirected_to profile_path
    follow_redirect!
    assert_match "520 L/min", flash[:notice]
  end

  test "POST /profile/personal_best with value below minimum fails and renders show" do
    assert_no_difference -> { @user.personal_best_records.count } do
      post profile_personal_best_path, params: { personal_best_record: { value: 50 } }
    end
    assert_response :unprocessable_entity
  end

  test "POST /profile/personal_best with value above maximum fails and renders show" do
    assert_no_difference -> { @user.personal_best_records.count } do
      post profile_personal_best_path, params: { personal_best_record: { value: 950 } }
    end
    assert_response :unprocessable_entity
  end

  test "POST /profile/personal_best returns JSON on success" do
    post profile_personal_best_path(format: :json), params: { personal_best_record: { value: 480 } }
    assert_response :created
    json = response.parsed_body
    assert_equal 480, json["value"]
    assert json["recorded_at"].present?
  end

  test "POST /profile/personal_best returns JSON errors on invalid value" do
    post profile_personal_best_path(format: :json), params: { personal_best_record: { value: 99 } }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert json["errors"].any? { |e| e.include?("100") || e.include?("900") },
           "Expected a range validation error, got: #{json['errors'].inspect}"
  end

  # ---------------------------------------------------------------------------
  # Security: email_address must not be updatable via profile_params
  # ---------------------------------------------------------------------------

  test "PATCH /profile does not permit changing email_address" do
    original_email = @user.email_address
    patch profile_path, params: { user: { email_address: "hacker@evil.com", full_name: "Hacked" } }
    @user.reload
    assert_equal original_email, @user.email_address
  end
end
