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

ActiveRecord::Schema[8.0].define(version: 2025_10_21_191447) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "benefit_limit_groups", force: :cascade do |t|
    t.bigint "plan_module_id", null: false
    t.string "name", null: false
    t.decimal "limit_usd", precision: 12, scale: 2
    t.decimal "limit_gbp", precision: 12, scale: 2
    t.decimal "limit_eur", precision: 12, scale: 2
    t.string "limit_unit", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_module_id"], name: "index_benefit_limit_groups_on_plan_module_id"
  end

  create_table "benefits", force: :cascade do |t|
    t.string "name", null: false
    t.integer "category", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cost_shares", force: :cascade do |t|
    t.string "scope_type", null: false
    t.bigint "scope_id", null: false
    t.integer "cost_share_type", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "unit", null: false
    t.integer "per", null: false
    t.string "currency"
    t.text "notes"
    t.integer "linked_cost_share_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scope_type", "scope_id"], name: "index_cost_shares_on_scope"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.bigint "region_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["region_id"], name: "index_countries_on_region_id"
  end

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

  create_table "module_benefits", force: :cascade do |t|
    t.bigint "plan_module_id", null: false
    t.bigint "benefit_id", null: false
    t.string "coverage_description"
    t.decimal "limit_usd", precision: 12, scale: 2
    t.decimal "limit_gbp", precision: 12, scale: 2
    t.decimal "limit_eur", precision: 12, scale: 2
    t.string "limit_unit"
    t.string "sub_limit_description"
    t.bigint "benefit_limit_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["benefit_id"], name: "index_module_benefits_on_benefit_id"
    t.index ["benefit_limit_group_id"], name: "index_module_benefits_on_benefit_limit_group_id"
    t.index ["plan_module_id"], name: "index_module_benefits_on_plan_module_id"
  end

  create_table "module_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
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

  create_table "plan_modules", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.string "name", null: false
    t.boolean "is_core", default: false, null: false
    t.bigint "depends_on_module_id"
    t.bigint "module_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "overall_limit_usd", precision: 12, scale: 2
    t.decimal "overall_limit_gbp", precision: 12, scale: 2
    t.decimal "overall_limit_eur", precision: 12, scale: 2
    t.string "overall_limit_unit"
    t.text "overall_limit_notes"
    t.index ["depends_on_module_id"], name: "index_plan_modules_on_depends_on_module_id"
    t.index ["module_group_id"], name: "index_plan_modules_on_module_group_id"
    t.index ["plan_id"], name: "index_plan_modules_on_plan_id"
  end

  create_table "plan_residency_eligibilities", force: :cascade do |t|
    t.bigint "plan_id", null: false
    t.bigint "country_id", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_plan_residency_eligibilities_on_country_id"
    t.index ["plan_id"], name: "index_plan_residency_eligibilities_on_plan_id"
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
    t.decimal "overall_limit_usd", precision: 12, scale: 2
    t.decimal "overall_limit_gbp", precision: 12, scale: 2
    t.decimal "overall_limit_eur", precision: 12, scale: 2
    t.string "overall_limit_unit"
    t.text "overall_limit_notes"
    t.boolean "overall_limit_unlimited", default: false, null: false
    t.index ["insurer_id"], name: "index_plans_on_insurer_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "benefit_limit_groups", "plan_modules"
  add_foreign_key "cost_shares", "cost_shares", column: "linked_cost_share_id"
  add_foreign_key "countries", "regions"
  add_foreign_key "module_benefits", "benefit_limit_groups"
  add_foreign_key "module_benefits", "benefits"
  add_foreign_key "module_benefits", "plan_modules"
  add_foreign_key "plan_geographic_cover_areas", "geographic_cover_areas"
  add_foreign_key "plan_geographic_cover_areas", "plans"
  add_foreign_key "plan_modules", "module_groups"
  add_foreign_key "plan_modules", "plan_modules", column: "depends_on_module_id"
  add_foreign_key "plan_modules", "plans"
  add_foreign_key "plan_residency_eligibilities", "countries"
  add_foreign_key "plan_residency_eligibilities", "plans"
  add_foreign_key "plans", "insurers"
end
