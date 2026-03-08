# frozen_string_literal: true
require "test_helper"

class MedicationTest < ActiveSupport::TestCase
  def setup
    @user = users(:verified_user)
  end

  def valid_attributes
    {
      user: @user,
      name: "Ventolin",
      medication_type: :reliever,
      standard_dose_puffs: 2,
      starting_dose_count: 200
    }
  end

  # Persistence

  test "valid medication saves with required fields only" do
    med = Medication.new(valid_attributes)
    assert med.save, med.errors.full_messages.inspect
  end

  test "valid medication saves with all optional fields" do
    med = Medication.new(
      valid_attributes.merge(
        medication_type: :preventer,
        sick_day_dose_puffs: 4,
        doses_per_day: 2
      )
    )
    assert med.save, med.errors.full_messages.inspect
  end

  # Enum

  test "medication_type enum accepts all four values" do
    %i[reliever preventer combination other].each do |type|
      med = Medication.new(valid_attributes.merge(medication_type: type))
      assert med.valid?, "Expected #{type} to be valid: #{med.errors.full_messages}"
    end
  end

  test "medication_type enum rejects unknown value" do
    med = Medication.new(valid_attributes.merge(medication_type: :unknown))
    assert_not med.valid?
    assert med.errors[:medication_type].any?
  end

  # Validations — required fields

  test "invalid without name" do
    med = Medication.new(valid_attributes.except(:name))
    assert_not med.valid?
    assert med.errors[:name].any?
  end

  test "invalid without medication_type" do
    med = Medication.new(valid_attributes.except(:medication_type))
    assert_not med.valid?
    assert med.errors[:medication_type].any?
  end

  test "invalid without standard_dose_puffs" do
    med = Medication.new(valid_attributes.except(:standard_dose_puffs))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "invalid without starting_dose_count" do
    med = Medication.new(valid_attributes.except(:starting_dose_count))
    assert_not med.valid?
    assert med.errors[:starting_dose_count].any?
  end

  test "invalid without user" do
    med = Medication.new(valid_attributes.except(:user))
    assert_not med.valid?
  end

  # Validations — numerics

  test "invalid when standard_dose_puffs is zero" do
    med = Medication.new(valid_attributes.merge(standard_dose_puffs: 0))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "invalid when standard_dose_puffs is negative" do
    med = Medication.new(valid_attributes.merge(standard_dose_puffs: -1))
    assert_not med.valid?
    assert med.errors[:standard_dose_puffs].any?
  end

  test "valid when starting_dose_count is zero" do
    med = Medication.new(valid_attributes.merge(starting_dose_count: 0))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "invalid when starting_dose_count is negative" do
    med = Medication.new(valid_attributes.merge(starting_dose_count: -1))
    assert_not med.valid?
    assert med.errors[:starting_dose_count].any?
  end

  test "invalid when sick_day_dose_puffs is zero" do
    med = Medication.new(valid_attributes.merge(sick_day_dose_puffs: 0))
    assert_not med.valid?
    assert med.errors[:sick_day_dose_puffs].any?
  end

  test "valid when sick_day_dose_puffs is nil" do
    med = Medication.new(valid_attributes.merge(sick_day_dose_puffs: nil))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "valid when doses_per_day is nil" do
    med = Medication.new(valid_attributes.merge(doses_per_day: nil))
    assert med.valid?, med.errors.full_messages.inspect
  end

  test "invalid when doses_per_day is zero" do
    med = Medication.new(valid_attributes.merge(doses_per_day: 0))
    assert_not med.valid?
    assert med.errors[:doses_per_day].any?
  end

  # Association

  test "belongs to user" do
    med = medications(:alice_reliever)
    assert_equal users(:verified_user), med.user
  end

  # Scope

  test "chronological scope orders by created_at descending" do
    assert_equal @user.medications.order(created_at: :desc).to_a,
                 @user.medications.chronological.to_a
  end
end
