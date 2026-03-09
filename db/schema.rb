# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_09_182935) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "dose_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "medication_id", null: false
    t.integer "puffs", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["medication_id", "recorded_at"], name: "index_dose_logs_on_medication_id_and_recorded_at"
    t.index ["medication_id"], name: "index_dose_logs_on_medication_id"
    t.index ["recorded_at"], name: "index_dose_logs_on_recorded_at"
    t.index ["user_id"], name: "index_dose_logs_on_user_id"
  end

  create_table "health_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.string "event_type", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "ended_at"], name: "index_health_events_on_user_id_and_ended_at"
    t.index ["user_id", "recorded_at"], name: "index_health_events_on_user_id_and_recorded_at"
    t.index ["user_id"], name: "index_health_events_on_user_id"
  end

  create_table "medications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "doses_per_day"
    t.integer "medication_type", null: false
    t.string "name", null: false
    t.datetime "refilled_at"
    t.integer "sick_day_dose_puffs"
    t.integer "standard_dose_puffs", null: false
    t.integer "starting_dose_count", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["medication_type"], name: "index_medications_on_medication_type"
    t.index ["user_id"], name: "index_medications_on_user_id"
  end

  create_table "peak_flow_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "recorded_at", null: false
    t.string "time_of_day"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value", null: false
    t.integer "zone"
    t.index ["user_id", "recorded_at"], name: "index_peak_flow_readings_on_user_id_and_recorded_at"
  end

  create_table "personal_best_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value", null: false
    t.index ["user_id", "recorded_at", "value"], name: "index_personal_best_records_covering"
    t.index ["user_id", "recorded_at"], name: "index_personal_best_records_on_user_id_and_recorded_at"
    t.index ["user_id"], name: "index_personal_best_records_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_sessions_on_created_at"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "symptom_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "recorded_at", null: false
    t.integer "severity", null: false
    t.integer "symptom_type", null: false
    t.text "triggers", default: "[]"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "recorded_at"], name: "index_symptom_logs_on_user_id_and_recorded_at"
    t.index ["user_id"], name: "index_symptom_logs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email_address", null: false
    t.datetime "email_verified_at"
    t.string "full_name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dose_logs", "medications"
  add_foreign_key "dose_logs", "users"
  add_foreign_key "health_events", "users"
  add_foreign_key "medications", "users"
  add_foreign_key "peak_flow_readings", "users"
  add_foreign_key "personal_best_records", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "symptom_logs", "users"
end
