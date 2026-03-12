# frozen_string_literal: true

class OptimizeSqliteIndexes < ActiveRecord::Migration[8.1]
  def change
    # ── dose_logs ──────────────────────────────────────────────────────────────
    #
    # Covering index for the remaining_doses SUM query:
    #   SELECT SUM(puffs) FROM dose_logs WHERE medication_id = ? AND recorded_at >= ?
    # Including puffs in the index allows an index-only scan — SQLite reads the
    # aggregate value directly from the index without touching the main table.
    add_index :dose_logs, %i[medication_id recorded_at puffs],
              name: "index_dose_logs_covering_remaining_doses"

    # Remove standalone medication_id index. Subsumed by the existing
    # (medication_id, recorded_at) composite and the new covering index above.
    # FK cascade lookups on dose_logs.medication_id use the leftmost prefix of
    # either composite, so this standalone index is redundant write overhead.
    remove_index :dose_logs, name: "index_dose_logs_on_medication_id"

    # ── health_events ─────────────────────────────────────────────────────────
    #
    # Covering index for the active illness query — runs on every dashboard request:
    #   WHERE user_id = ? AND event_type = 'illness' AND ended_at IS NULL
    #   ORDER BY recorded_at DESC LIMIT 1
    # Preceding (user_id, ended_at) and (user_id, recorded_at) each cover part of
    # this query; this composite covers the whole predicate and sort in one scan.
    add_index :health_events, %i[user_id event_type ended_at recorded_at],
              name: "index_health_events_covering_illness_query"

    # Remove standalone user_id index. Subsumed by (user_id, recorded_at),
    # (user_id, ended_at), and the new covering index.
    remove_index :health_events, name: "index_health_events_on_user_id"

    # ── symptom_logs ──────────────────────────────────────────────────────────
    #
    # Covering index for severity-filtered symptom queries:
    #   @last_severe:      WHERE user_id = ? AND severity = ? ORDER BY recorded_at DESC LIMIT 1
    #   severity_counts:   WHERE user_id = ? AND recorded_at >= ? GROUP BY severity
    # The existing (user_id, recorded_at) index cannot satisfy the severity predicate
    # without a table scan. This composite eliminates the table row lookups entirely.
    add_index :symptom_logs, %i[user_id severity recorded_at],
              name: "index_symptom_logs_covering_severity"

    # ── medications ───────────────────────────────────────────────────────────
    #
    # Covering index for course medication queries used in MedicationsController#index
    # and the active_courses / archived_courses scopes:
    #   WHERE user_id = ? AND course = true AND ends_on >= ?
    add_index :medications, %i[user_id course ends_on],
              name: "index_medications_covering_course_queries"

    # Remove standalone ends_on index. Subsumed by the new composite above.
    remove_index :medications, name: "index_medications_on_ends_on"

    # ── peak_flow_readings ────────────────────────────────────────────────────
    #
    # Covering index for the dashboard chart data pluck query:
    #   .pluck(:recorded_at, :value, :zone, :time_of_day) WHERE user_id = ? ORDER BY recorded_at
    # Also covers: today's best reading query (user_id + date range + ORDER BY value DESC).
    # Without this, the existing (user_id, recorded_at) index satisfies the predicate but
    # forces a table lookup for each row to read value, zone, and time_of_day.
    add_index :peak_flow_readings, %i[user_id recorded_at value zone time_of_day],
              name: "index_peak_flow_readings_covering_chart"

    # ── notifications ─────────────────────────────────────────────────────────
    #
    # Remove standalone user_id index. Fully subsumed by (user_id, read), which
    # is used for every badge count query and covers FK cascade lookups.
    remove_index :notifications, name: "index_notifications_on_user_id"
  end
end
