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

ActiveRecord::Schema[8.0].define(version: 2025_10_09_142919) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "geographic_cover_areas", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "insurers", force: :cascade do |t|
    t.string "name"
    t.string "jurisdiction"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plan_geographic_cover_areas", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "geographic_cover_area_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geographic_cover_area_id"], name: "index_plan_geographic_cover_areas_on_geographic_cover_area_id"
    t.index ["plan_id"], name: "index_plan_geographic_cover_areas_on_plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.bigint "insurer_id", null: false
    t.string "name", null: false
    t.integer "min_age", default: 0, null: false
    t.integer "max_age"
    t.boolean "children_only_allowed", default: false, null: false
    t.integer "version_year", null: false
    t.boolean "published", default: false, null: false
    t.integer "policy_type", null: false
    t.date "last_reviewed_at"
    t.date "next_review_due", null: false
    t.text "review_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["insurer_id"], name: "index_plans_on_insurer_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "plan_geographic_cover_areas", "geographic_cover_areas"
  add_foreign_key "plan_geographic_cover_areas", "plans"
  add_foreign_key "plans", "insurers"
end
