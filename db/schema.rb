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

ActiveRecord::Schema[7.0].define(version: 2025_09_02_143910) do
  create_table "conflict_resolution_tasks", force: :cascade do |t|
    t.integer "sync_session_id", null: false
    t.string "conflict_type"
    t.string "status"
    t.text "local_data"
    t.text "remote_data"
    t.text "resolution_data"
    t.text "conflict_analysis"
    t.datetime "resolved_at"
    t.string "resolved_by"
    t.string "resolution_strategy"
    t.text "rejection_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sync_session_id"], name: "index_conflict_resolution_tasks_on_sync_session_id"
  end

  create_table "sync_sessions", force: :cascade do |t|
    t.integer "todo_list_id", null: false
    t.string "status"
    t.string "strategy"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "local_changes_count"
    t.integer "remote_changes_count"
    t.integer "conflicts_count"
    t.text "sync_results"
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["todo_list_id"], name: "index_sync_sessions_on_todo_list_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.string "description"
    t.boolean "completed"
    t.integer "todo_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.datetime "synced_at"
    t.index ["todo_list_id"], name: "index_todo_items_on_todo_list_id"
  end

  create_table "todo_lists", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.datetime "synced_at"
    t.boolean "sync_enabled"
  end

  add_foreign_key "conflict_resolution_tasks", "sync_sessions"
  add_foreign_key "sync_sessions", "todo_lists"
  add_foreign_key "todo_items", "todo_lists"
end
