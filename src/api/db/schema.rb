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

ActiveRecord::Schema[7.2].define(version: 2026_07_04_010006) do
  create_table "account_categories", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.index ["code"], name: "index_account_categories_on_code", unique: true
  end

  create_table "amount_labels", force: :cascade do |t|
    t.string "label", null: false
    t.string "kind", null: false
    t.integer "priority", default: 0, null: false
    t.index ["label"], name: "index_amount_labels_on_label", unique: true
  end

  create_table "classify_rules", force: :cascade do |t|
    t.integer "account_category_id", null: false
    t.string "keyword", null: false
    t.integer "priority", default: 1, null: false
    t.index ["account_category_id"], name: "index_classify_rules_on_account_category_id"
    t.index ["keyword"], name: "index_classify_rules_on_keyword"
  end

  create_table "receipts", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "category_id"
    t.date "issued_on"
    t.integer "amount_yen"
    t.string "store_name"
    t.string "image_path"
    t.float "ocr_confidence"
    t.boolean "manually_edited", default: false, null: false
    t.datetime "created_at", null: false
    t.index ["session_id", "category_id"], name: "index_receipts_on_session_id_and_category_id"
    t.index ["session_id"], name: "index_receipts_on_session_id"
  end

  create_table "reports", force: :cascade do |t|
    t.string "session_id", null: false
    t.integer "target_year", null: false
    t.string "pdf_path", null: false
    t.datetime "generated_at", null: false
    t.index ["session_id"], name: "index_reports_on_session_id"
  end

  create_table "sessions", id: false, force: :cascade do |t|
    t.string "session_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_accessed_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
  end

  add_foreign_key "classify_rules", "account_categories"
end
