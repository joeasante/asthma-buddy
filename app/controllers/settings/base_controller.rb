# frozen_string_literal: true

class Settings::BaseController < ApplicationController
  include DashboardVariables

  private

  def set_header_eyebrow_vars
    all_meds = Current.user.medications.chronological.includes(:dose_logs)
    visible  = all_meds.reject { |m| m.course? && !m.course_active? }
    @header_medication_count = visible.size
    @header_low_stock_count  = visible.count(&:low_stock?)
  end

end
