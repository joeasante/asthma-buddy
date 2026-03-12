# frozen_string_literal: true

class OptimiseSqliteIndexesPhase2 < ActiveRecord::Migration[8.1]
  def change
    # ── Remove redundant standalone user_id indexes ────────────────────────────
    #
    # Each is fully subsumed by a composite index whose leftmost column is user_id.
    # FK cascade deletes on users use the leftmost prefix of the composite, so the
    # standalone index is write overhead with zero query benefit.
    #
    # dose_logs: subsumed by (user_id, medication_id, recorded_at)
    remove_index :dose_logs, name: "index_dose_logs_on_user_id"

    # symptom_logs: subsumed by covering (user_id, severity, recorded_at)
    remove_index :symptom_logs, name: "index_symptom_logs_on_user_id"

    # medications: subsumed by covering (user_id, course, ends_on)
    remove_index :medications, name: "index_medications_on_user_id"

    # personal_best_records: subsumed by (user_id, recorded_at)
    remove_index :personal_best_records, name: "index_personal_best_records_on_user_id"

    # ── Add index for PruneNotificationsJob ────────────────────────────────────
    #
    # PruneNotificationsJob runs: Notification.pruneable.delete_all
    # which resolves to: WHERE read = true AND created_at < 90.days.ago
    # No existing index covers this — without it the job does a full table scan.
    # This composite allows an index-only scan for the prune DELETE.
    add_index :notifications, %i[read created_at],
              name: "index_notifications_on_read_and_created_at"
  end
end
