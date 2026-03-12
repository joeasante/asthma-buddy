# frozen_string_literal: true

class ProfilesController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :update, with: -> {
    respond_to do |format|
      format.html { redirect_to profile_path, alert: "Too many updates. Try again in a moment." }
      format.json { render json: { error: "Rate limit exceeded." }, status: :too_many_requests }
    end
  }

  before_action :set_profile_data, only: %i[show update update_personal_best]

  def show
    respond_to do |format|
      format.html
      format.json { render json: profile_json }
    end
  end

  def update
    @form_section = params[:_profile_section].presence || detect_form_section
    update_attrs = profile_params

    if update_attrs[:password].blank?
      update_attrs.delete(:password)
      update_attrs.delete(:password_confirmation)
    end

    if update_attrs[:password].present?
      current_password = params.dig(:user, :current_password)
      unless Current.user.authenticate(current_password.to_s)
        Current.user.errors.add(:current_password, "is incorrect")
        respond_to do |format|
          format.turbo_stream { render :update, status: :unprocessable_entity }
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: { errors: Current.user.errors.full_messages }, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      if Current.user.update(update_attrs)
        format.turbo_stream
        format.html { redirect_to profile_path, notice: "Profile updated." }
        format.json { render json: profile_json }
      else
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: Current.user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update_personal_best
    @personal_best_record = Current.user.personal_best_records.new(personal_best_params)

    respond_to do |format|
      if @personal_best_record.save
        @current_personal_best = @personal_best_record
        format.turbo_stream
        format.html { redirect_to profile_path, notice: "Personal best updated to #{@personal_best_record.value} L/min." }
        format.json { render json: { value: @personal_best_record.value, recorded_at: @personal_best_record.recorded_at }, status: :created }
      else
        format.turbo_stream { render :update_personal_best, status: :unprocessable_entity }
        format.html { render :show, status: :unprocessable_entity }
        format.json { render json: { errors: @personal_best_record.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def remove_avatar
    Current.user.avatar.purge
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to profile_path, notice: "Profile photo removed." }
      format.json { render json: { success: true } }
    end
  end

  private

  def set_profile_data
    @current_personal_best = PersonalBestRecord.current_for(Current.user)
    # Build via class-level new so the unsaved record is not added to the user's
    # in-memory association target, which would cause validation failures when
    # Current.user.update is called for unrelated profile attribute changes.
    @personal_best_record  = PersonalBestRecord.new(user: Current.user, recorded_at: Time.current)
    @medications = Current.user.medications.chronological
  end

  def detect_form_section
    if params[:user]&.key?(:avatar)
      "avatar"
    elsif params[:user]&.key?(:password)
      "password"
    else
      "details"
    end
  end

  # Email address excluded deliberately: changing email requires a re-verification
  # flow (future work). Allowing unverified email changes is an account-takeover vector.
  def profile_params
    params.require(:user).permit(:full_name, :date_of_birth, :password, :password_confirmation, :avatar)
  end

  def personal_best_params
    # Use beginning_of_minute to match the peak flow reading default (sec: 0),
    # preventing same-minute zone classification mismatches.
    params.require(:personal_best_record).permit(:value).merge(recorded_at: Time.current.change(sec: 0))
  end

  def profile_json
    {
      id:            Current.user.id,
      full_name:     Current.user.full_name,
      date_of_birth: Current.user.date_of_birth,
      avatar_url:    Current.user.avatar.attached? ? url_for(Current.user.avatar) : nil
    }
  end
end
