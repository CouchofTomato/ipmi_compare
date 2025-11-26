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

ActiveRecord::Schema[8.1].define(version: 2025_11_26_210056) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "benefit_limit_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "limit_eur", precision: 12, scale: 2
    t.decimal "limit_gbp", precision: 12, scale: 2
    t.string "limit_unit", null: false
    t.decimal "limit_usd", precision: 12, scale: 2
    t.string "name", null: false
    t.text "notes"
    t.bigint "plan_module_id", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_module_id"], name: "index_benefit_limit_groups_on_plan_module_id"
  end

  create_table "benefits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cost_share_links", force: :cascade do |t|
    t.bigint "cost_share_id", null: false
    t.datetime "created_at", null: false
    t.bigint "linked_cost_share_id", null: false
    t.integer "relationship_type", default: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["cost_share_id", "linked_cost_share_id"], name: "idx_cost_share_links_uniqueness", unique: true
    t.index ["cost_share_id"], name: "index_cost_share_links_on_cost_share_id"
    t.index ["linked_cost_share_id"], name: "index_cost_share_links_on_linked_cost_share_id"
  end

  create_table "cost_shares", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "cost_share_type", null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.bigint "linked_cost_share_id"
    t.text "notes"
    t.integer "per", null: false
    t.bigint "scope_id", null: false
    t.string "scope_type", null: false
    t.integer "unit", null: false
    t.datetime "updated_at", null: false
    t.index ["linked_cost_share_id"], name: "index_cost_shares_on_linked_cost_share_id"
    t.index ["scope_type", "scope_id"], name: "index_cost_shares_on_scope"
  end

  create_table "coverage_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_coverage_categories_on_name", unique: true
    t.index ["position"], name: "index_coverage_categories_on_position"
  end

  create_table "coverage_categories_plan_modules", id: false, force: :cascade do |t|
    t.bigint "coverage_category_id", null: false
    t.bigint "plan_module_id", null: false
    t.index ["plan_module_id", "coverage_category_id"], name: "idx_ccpm_unique", unique: true
  end

  create_table "geographic_cover_areas", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "insurers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "jurisdiction"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "module_benefits", force: :cascade do |t|
    t.bigint "benefit_id", null: false
    t.bigint "benefit_limit_group_id"
    t.bigint "coverage_category_id", null: false
    t.string "coverage_description"
    t.datetime "created_at", null: false
    t.integer "interaction_type", default: 1, null: false
    t.decimal "limit_eur", precision: 12, scale: 2
    t.decimal "limit_gbp", precision: 12, scale: 2
    t.string "limit_unit"
    t.decimal "limit_usd", precision: 12, scale: 2
    t.bigint "plan_module_id", null: false
    t.string "sub_limit_description"
    t.datetime "updated_at", null: false
    t.integer "weighting", default: 0, null: false
    t.index ["benefit_id"], name: "index_module_benefits_on_benefit_id"
    t.index ["benefit_limit_group_id"], name: "index_module_benefits_on_benefit_limit_group_id"
    t.index ["coverage_category_id"], name: "index_module_benefits_on_coverage_category_id"
    t.index ["interaction_type"], name: "index_module_benefits_on_interaction_type"
    t.index ["plan_module_id"], name: "index_module_benefits_on_plan_module_id"
    t.index ["weighting"], name: "index_module_benefits_on_weighting"
  end

  create_table "module_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "plan_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_module_groups_on_plan_id"
  end

  create_table "plan_geographic_cover_areas", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "geographic_cover_area_id", null: false
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["geographic_cover_area_id"], name: "index_plan_geographic_cover_areas_on_geographic_cover_area_id"
    t.index ["plan_id"], name: "index_plan_geographic_cover_areas_on_plan_id"
  end

  create_table "plan_module_requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dependent_module_id", null: false
    t.bigint "plan_id", null: false
    t.bigint "required_module_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_module_id"], name: "index_plan_module_requirements_on_dependent_module_id"
    t.index ["plan_id", "dependent_module_id", "required_module_id"], name: "idx_pmr_plan_module_requires_unique", unique: true
    t.index ["plan_id"], name: "index_plan_module_requirements_on_plan_id"
    t.index ["required_module_id"], name: "index_plan_module_requirements_on_required_module_id"
  end

  create_table "plan_modules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_core", default: false, null: false
    t.bigint "module_group_id", null: false
    t.string "name", null: false
    t.decimal "overall_limit_eur", precision: 12, scale: 2
    t.decimal "overall_limit_gbp", precision: 12, scale: 2
    t.text "overall_limit_notes"
    t.string "overall_limit_unit"
    t.decimal "overall_limit_usd", precision: 12, scale: 2
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["module_group_id"], name: "index_plan_modules_on_module_group_id"
    t.index ["plan_id"], name: "index_plan_modules_on_plan_id"
  end

  create_table "plan_residency_eligibilities", force: :cascade do |t|
    t.string "country_code", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.bigint "plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_plan_residency_eligibilities_on_plan_id"
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "children_only_allowed", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "insurer_id", null: false
    t.date "last_reviewed_at"
    t.integer "max_age"
    t.integer "min_age", default: 0, null: false
    t.string "name", null: false
    t.date "next_review_due", null: false
    t.integer "policy_type", null: false
    t.boolean "published", default: false, null: false
    t.text "review_notes"
    t.datetime "updated_at", null: false
    t.integer "version_year", null: false
    t.index ["insurer_id"], name: "index_plans_on_insurer_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_created_at"
    t.integer "invitation_limit"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.integer "invitations_count", default: 0
    t.bigint "invited_by_id"
    t.string "invited_by_type"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "wizard_progresses", force: :cascade do |t|
    t.datetime "abandoned_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "current_step", null: false
    t.datetime "expires_at"
    t.bigint "last_actor_id"
    t.string "last_event"
    t.datetime "last_interaction_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "started_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "status", default: "in_progress", null: false
    t.integer "step_order", default: 0, null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "wizard_type", null: false
    t.index ["last_actor_id"], name: "index_wizard_progresses_on_last_actor_id"
    t.index ["status", "updated_at"], name: "index_wizard_progresses_on_status_and_updated_at"
    t.index ["subject_type", "subject_id"], name: "index_wizard_progresses_on_subject"
    t.index ["user_id"], name: "index_wizard_progresses_on_user_id"
    t.index ["wizard_type", "subject_type", "subject_id"], name: "index_wizard_progresses_on_type_and_subject", unique: true, where: "(subject_id IS NOT NULL)"
    t.index ["wizard_type"], name: "index_wizard_progresses_on_wizard_type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "benefit_limit_groups", "plan_modules"
  add_foreign_key "cost_share_links", "cost_shares"
  add_foreign_key "cost_share_links", "cost_shares", column: "linked_cost_share_id"
  add_foreign_key "cost_shares", "cost_shares", column: "linked_cost_share_id"
  add_foreign_key "coverage_categories_plan_modules", "coverage_categories"
  add_foreign_key "coverage_categories_plan_modules", "plan_modules"
  add_foreign_key "module_benefits", "benefit_limit_groups"
  add_foreign_key "module_benefits", "benefits"
  add_foreign_key "module_benefits", "coverage_categories"
  add_foreign_key "module_benefits", "plan_modules"
  add_foreign_key "module_groups", "plans"
  add_foreign_key "plan_geographic_cover_areas", "geographic_cover_areas"
  add_foreign_key "plan_geographic_cover_areas", "plans"
  add_foreign_key "plan_module_requirements", "plan_modules", column: "dependent_module_id"
  add_foreign_key "plan_module_requirements", "plan_modules", column: "required_module_id"
  add_foreign_key "plan_module_requirements", "plans"
  add_foreign_key "plan_modules", "module_groups"
  add_foreign_key "plan_modules", "plans"
  add_foreign_key "plan_residency_eligibilities", "plans"
  add_foreign_key "plans", "insurers"
  add_foreign_key "wizard_progresses", "users"
  add_foreign_key "wizard_progresses", "users", column: "last_actor_id"
end
