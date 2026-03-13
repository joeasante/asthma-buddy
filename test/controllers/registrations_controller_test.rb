# frozen_string_literal: true

require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET /registration/new returns 200 with signup form" do
    get new_registration_path
    assert_response :success
    assert_select "form"
    assert_select "input[type=email]"
    assert_select "input[type=password]"
  end

  test "POST /registration with valid params creates user and redirects" do
    assert_difference "User.count", 1 do
      post registration_path, params: {
        user: { email_address: "newuser@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_redirected_to new_session_path
    assert_equal "Account created. Please check your email to verify your account.", flash[:notice]
  end

  test "POST /registration with duplicate email returns 422" do
    post registration_path, params: {
      user: { email_address: users(:verified_user).email_address, password: "password123", password_confirmation: "password123" }
    }
    assert_response :unprocessable_entity
  end

  test "POST /registration with short password returns 422" do
    post registration_path, params: {
      user: { email_address: "newuser@example.com", password: "short", password_confirmation: "short" }
    }
    assert_response :unprocessable_entity
  end

  test "POST /registration with mismatched password_confirmation returns 422" do
    post registration_path, params: {
      user: { email_address: "newuser@example.com", password: "password123", password_confirmation: "different456" }
    }
    assert_response :unprocessable_entity
  end

  test "POST /registration with valid params enqueues email verification and admin notification" do
    assert_enqueued_emails 2 do
      post registration_path, params: {
        user: { email_address: "newuser@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
  end

  # --- JSON ---

  test "POST /registration with valid params returns 201 JSON" do
    assert_difference "User.count", 1 do
      post registration_path,
        params: { user: { email_address: "jsonuser@example.com", password: "password123", password_confirmation: "password123" } },
        as: :json
    end
    assert_response :created
    assert_match "verify", response.parsed_body["message"]
  end

  test "POST /registration with duplicate email returns 422 JSON with errors" do
    post registration_path,
      params: { user: { email_address: users(:verified_user).email_address, password: "password123", password_confirmation: "password123" } },
      as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  test "POST /registration with short password returns 422 JSON with errors" do
    post registration_path,
      params: { user: { email_address: "newuser@example.com", password: "short", password_confirmation: "short" } },
      as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end
end
