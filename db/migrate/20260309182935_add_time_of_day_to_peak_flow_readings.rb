class AddTimeOfDayToPeakFlowReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :peak_flow_readings, :time_of_day, :string

    # Best-effort backfill: infer session from recorded_at timestamp.
    # Before 13:00 = morning, 13:00+ = evening. Good enough for historical data.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE peak_flow_readings
          SET time_of_day = CASE
            WHEN CAST(strftime('%H', recorded_at) AS INTEGER) < 13 THEN 'morning'
            ELSE 'evening'
          END
        SQL
      end
    end
  end
end
