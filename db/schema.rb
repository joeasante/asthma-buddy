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

ActiveRecord::Schema[8.1].define(version: 2026_03_15_004609) do
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
    t.index ["medication_id", "recorded_at", "puffs"], name: "index_dose_logs_covering_remaining_doses"
    t.index ["medication_id", "recorded_at"], name: "index_dose_logs_on_medication_id_and_recorded_at"
    t.index ["recorded_at"], name: "index_dose_logs_on_recorded_at"
    t.index ["user_id", "medication_id", "recorded_at"], name: "index_dose_logs_on_user_medication_recorded_at"
  end

  create_table "health_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.string "event_type", null: false
    t.datetime "recorded_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "ended_at"], name: "index_health_events_on_user_id_and_ended_at"
    t.index ["user_id", "event_type", "ended_at", "recorded_at"], name: "index_health_events_covering_illness_query"
    t.index ["user_id", "recorded_at"], name: "index_health_events_on_user_id_and_recorded_at"
  end

  create_table "medications", force: :cascade do |t|
    t.boolean "course", default: false, null: false
    t.datetime "created_at", null: false
    t.string "dose_unit", default: "puffs", null: false
    t.integer "doses_per_day"
    t.date "ends_on"
    t.integer "medication_type", null: false
    t.string "name", null: false
    t.datetime "refilled_at"
    t.integer "sick_day_dose_puffs"
    t.integer "standard_dose_puffs"
    t.integer "starting_dose_count"
    t.date "starts_on"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["medication_type"], name: "index_medications_on_medication_type"
    t.index ["user_id", "course", "ends_on"], name: "index_medications_covering_course_queries"
    t.check_constraint "dose_unit IN ('puffs', 'tablets', 'ml')", name: "medications_dose_unit_check"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.integer "notification_type", null: false
    t.boolean "read", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["read", "created_at"], name: "index_notifications_on_read_and_created_at"
    t.index ["user_id", "notifiable_type", "notifiable_id", "notification_type"], name: "index_notifications_unique_unread_per_notifiable", unique: true, where: "read = 0"
    t.index ["user_id", "notification_type", "notifiable_type", "notifiable_id"], name: "index_notifications_deduplication"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
  end

  create_table "pay_charges", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "amount_refunded"
    t.integer "application_fee_amount"
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "customer_id", null: false
    t.json "data"
    t.json "metadata"
    t.json "object"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.bigint "subscription_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_charges_on_customer_id_and_processor_id", unique: true
    t.index ["subscription_id"], name: "index_pay_charges_on_subscription_id"
  end

  create_table "pay_customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.boolean "default"
    t.datetime "deleted_at", precision: nil
    t.json "object"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "deleted_at"], name: "pay_customer_owner_index", unique: true
    t.index ["processor", "processor_id"], name: "index_pay_customers_on_processor_and_processor_id", unique: true
  end

  create_table "pay_merchants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data"
    t.boolean "default"
    t.bigint "owner_id"
    t.string "owner_type"
    t.string "processor", null: false
    t.string "processor_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id", "processor"], name: "index_pay_merchants_on_owner_type_and_owner_id_and_processor"
  end

  create_table "pay_payment_methods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.json "data"
    t.boolean "default"
    t.string "payment_method_type"
    t.string "processor_id", null: false
    t.string "stripe_account"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_payment_methods_on_customer_id_and_processor_id", unique: true
  end

  create_table "pay_subscriptions", force: :cascade do |t|
    t.decimal "application_fee_percent", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "current_period_end", precision: nil
    t.datetime "current_period_start", precision: nil
    t.bigint "customer_id", null: false
    t.json "data"
    t.datetime "ends_at", precision: nil
    t.json "metadata"
    t.boolean "metered"
    t.string "name", null: false
    t.json "object"
    t.string "pause_behavior"
    t.datetime "pause_resumes_at", precision: nil
    t.datetime "pause_starts_at", precision: nil
    t.string "payment_method_id"
    t.string "processor_id", null: false
    t.string "processor_plan", null: false
    t.integer "quantity", default: 1, null: false
    t.string "status", null: false
    t.string "stripe_account"
    t.datetime "trial_ends_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["customer_id", "processor_id"], name: "index_pay_subscriptions_on_customer_id_and_processor_id", unique: true
    t.index ["metered"], name: "index_pay_subscriptions_on_metered"
    t.index ["pause_starts_at"], name: "index_pay_subscriptions_on_pause_starts_at"
  end

  create_table "pay_webhooks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "event"
    t.string "event_type"
    t.string "processor"
    t.datetime "updated_at", null: false
  end

  create_table "peak_flow_readings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "recorded_at", null: false
    t.string "time_of_day"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value", null: false
    t.integer "zone"
    t.index "user_id, time_of_day, DATE(recorded_at)", name: "index_peak_flow_readings_unique_session_per_day", unique: true
    t.index ["user_id", "recorded_at", "value", "zone", "time_of_day"], name: "index_peak_flow_readings_covering_chart"
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

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

# Could not dump table "sqlite_stat1" because of following StandardError
#   Unknown type '' for column 'idx'


  create_table "symptom_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "recorded_at", null: false
    t.integer "severity", null: false
    t.integer "symptom_type", null: false
    t.text "triggers", default: "[]"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "recorded_at"], name: "index_symptom_logs_on_user_id_and_recorded_at"
    t.index ["user_id", "severity", "recorded_at"], name: "index_symptom_logs_covering_severity"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "api_key_created_at"
    t.string "api_key_digest"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "email_address", null: false
    t.datetime "email_verified_at"
    t.string "full_name"
    t.datetime "last_otp_at"
    t.datetime "last_sign_in_at"
    t.boolean "onboarding_medication_done", default: false, null: false
    t.boolean "onboarding_personal_best_done", default: false, null: false
    t.text "otp_recovery_codes"
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_secret"
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_users_on_api_key_digest", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["last_sign_in_at"], name: "index_users_on_last_sign_in_at"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dose_logs", "medications"
  add_foreign_key "dose_logs", "users"
  add_foreign_key "health_events", "users"
  add_foreign_key "medications", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "pay_charges", "pay_customers", column: "customer_id"
  add_foreign_key "pay_charges", "pay_subscriptions", column: "subscription_id"
  add_foreign_key "pay_payment_methods", "pay_customers", column: "customer_id"
  add_foreign_key "pay_subscriptions", "pay_customers", column: "customer_id"
  add_foreign_key "peak_flow_readings", "users"
  add_foreign_key "personal_best_records", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "symptom_logs", "users"
end
