# frozen_string_literal: true

class BackfillNilZonePeakFlowReadings < ActiveRecord::Migration[8.1]
  def up
    # Re-run zone computation for every reading that has no zone.
    # Uses the most recent personal best recorded on or before the reading date.
    #
    # Constants are inlined as they existed when this migration was written (2026-03-08)
    # so re-running against a fresh database produces consistent results regardless of
    # future model changes. Do NOT replace these literals with model constants.
    # PeakFlowReading::GREEN_ZONE_THRESHOLD  = 80
    # PeakFlowReading::YELLOW_ZONE_THRESHOLD = 50
    # PeakFlowReading.zones = { "green" => 0, "yellow" => 1, "red" => 2 }
    green_zone_threshold  = 80
    yellow_zone_threshold = 50
    zone_map = { "green" => 0, "yellow" => 1, "red" => 2 }.freeze

    User.find_each do |user|
      user.peak_flow_readings.where(zone: nil).each do |reading|
        pb_value = user.personal_best_records
                       .where(recorded_at: ..reading.recorded_at.end_of_day)
                       .order(recorded_at: :desc)
                       .pick(:value)
        next unless pb_value&.positive?

        pct = (reading.value.to_f / pb_value) * 100
        zone = if pct >= green_zone_threshold then "green"
        elsif pct >= yellow_zone_threshold then "yellow"
        else "red"
        end
        reading.update_column(:zone, zone_map[zone])
      end
    end
  end

  def down
    # Zone values written by this migration cannot be automatically reverted.
    # rake db:rollback will silently succeed without changing any data.
    # To revert, restore from a database snapshot taken before this migration ran.
  end
end
