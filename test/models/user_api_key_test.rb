# frozen_string_literal: true

require "test_helper"

class UserApiKeyTest < ActiveSupport::TestCase
  setup do
    @user = users(:verified_user)
  end

  test "generate_api_key! returns a 64-char hex string" do
    token = @user.generate_api_key!
    assert_match(/\A[0-9a-f]{64}\z/, token)
  end

  test "generate_api_key! stores a non-nil digest different from the plaintext" do
    token = @user.generate_api_key!
    @user.reload
    assert_not_nil @user.api_key_digest
    assert_not_equal token, @user.api_key_digest
  end

  test "generate_api_key! sets api_key_created_at" do
    assert_nil @user.api_key_created_at
    @user.generate_api_key!
    @user.reload
    assert_not_nil @user.api_key_created_at
  end

  test "calling generate_api_key! again replaces the previous key" do
    @user.generate_api_key!
    old_digest = @user.reload.api_key_digest

    @user.generate_api_key!
    new_digest = @user.reload.api_key_digest

    assert_not_equal old_digest, new_digest
  end

  test "revoke_api_key! clears digest and created_at" do
    @user.generate_api_key!
    @user.revoke_api_key!
    @user.reload

    assert_nil @user.api_key_digest
    assert_nil @user.api_key_created_at
  end

  test "User.authenticate_by_api_key with valid token returns the user" do
    token = @user.generate_api_key!
    assert_equal @user, User.authenticate_by_api_key(token)
  end

  test "User.authenticate_by_api_key with invalid token returns nil" do
    @user.generate_api_key!
    assert_nil User.authenticate_by_api_key("invalid_token")
  end

  test "User.authenticate_by_api_key with nil returns nil" do
    assert_nil User.authenticate_by_api_key(nil)
  end

  test "User.authenticate_by_api_key with blank returns nil" do
    assert_nil User.authenticate_by_api_key("")
  end

  test "User.authenticate_by_api_key after revocation returns nil" do
    token = @user.generate_api_key!
    @user.revoke_api_key!
    assert_nil User.authenticate_by_api_key(token)
  end

  test "api_key_active? returns true when key exists" do
    @user.generate_api_key!
    assert @user.api_key_active?
  end

  test "api_key_active? returns false after revocation" do
    @user.generate_api_key!
    @user.revoke_api_key!
    assert_not @user.api_key_active?
  end

  test "authenticate_by_api_key rejects expired keys" do
    token = @user.generate_api_key!
    @user.update_column(:api_key_created_at, 181.days.ago)
    assert_nil User.authenticate_by_api_key(token)
  end

  test "authenticate_by_api_key accepts keys within TTL" do
    token = @user.generate_api_key!
    @user.update_column(:api_key_created_at, 179.days.ago)
    assert_equal @user, User.authenticate_by_api_key(token)
  end

  test "api_key_expired? returns true for old keys" do
    @user.generate_api_key!
    @user.update_column(:api_key_created_at, 181.days.ago)
    assert @user.api_key_expired?
  end

  test "api_key_expired? returns false for fresh keys" do
    @user.generate_api_key!
    assert_not @user.api_key_expired?
  end

  test "api_key_expires_at returns correct date" do
    @user.generate_api_key!
    expected = @user.api_key_created_at + ApiAuthenticatable::API_KEY_TTL
    assert_equal expected.to_i, @user.api_key_expires_at.to_i
  end
end
