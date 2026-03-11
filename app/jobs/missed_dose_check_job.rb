# frozen_string_literal: true

class MissedDoseCheckJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.current

    # Only non-course preventers with a doses_per_day schedule.
    # includes(:user) avoids N+1 for user lookups.
    # DoseLog.where SQL count avoids loading the full dose_logs association per medication.
    Medication.non_courses
              .where(medication_type: Medication.medication_types[:preventer])
              .where.not(doses_per_day: nil)
              .includes(:user)
              .find_each do |medication|

      doses_logged_today = DoseLog.where(
        medication: medication,
        recorded_at: today.beginning_of_day..today.end_of_day
      ).count

      next if doses_logged_today >= medication.doses_per_day

      # Deduplication: skip if already created a missed_dose notification for this
      # medication today (one per calendar day per medication)
      next if Notification.exists?(
        user:              medication.user,
        notification_type: :missed_dose,
        notifiable:        medication,
        created_at:        today.beginning_of_day..today.end_of_day
      )

      Notification.create!(
        user:              medication.user,
        notification_type: :missed_dose,
        notifiable:        medication,
        body:              "You haven't logged your #{medication.name} dose today."
      )
    end
  end
end
