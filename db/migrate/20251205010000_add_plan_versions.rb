class AddPlanVersions < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  class Plan < ApplicationRecord
    self.table_name = "plans"
  end

  class PlanVersion < ApplicationRecord
    self.table_name = "plan_versions"
  end

  class ModuleGroup < ApplicationRecord
    self.table_name = "module_groups"
  end

  class PlanModule < ApplicationRecord
    self.table_name = "plan_modules"
  end

  class PlanGeographicCoverArea < ApplicationRecord
    self.table_name = "plan_geographic_cover_areas"
  end

  class PlanResidencyEligibility < ApplicationRecord
    self.table_name = "plan_residency_eligibilities"
  end

  class PlanModuleRequirement < ApplicationRecord
    self.table_name = "plan_module_requirements"
  end

  class CostShare < ApplicationRecord
    self.table_name = "cost_shares"
  end

  def up
    create_table :plan_versions do |t|
      t.references :plan, null: false, foreign_key: true
      t.integer :version_year, null: false
      t.boolean :children_only_allowed, null: false, default: false
      t.integer :min_age, null: false, default: 0
      t.integer :max_age
      t.integer :policy_type, null: false
      t.boolean :published, null: false, default: false
      t.date :last_reviewed_at
      t.date :next_review_due, null: false
      t.text :review_notes
      t.boolean :current, null: false, default: false
      t.timestamps
    end

    add_index :plan_versions, [ :plan_id ], unique: true, where: "current", name: "index_plan_versions_on_plan_id_current"

    add_reference :module_groups, :plan_version, foreign_key: true
    add_reference :plan_modules, :plan_version, foreign_key: true
    add_reference :plan_geographic_cover_areas, :plan_version, foreign_key: true
    add_reference :plan_residency_eligibilities, :plan_version, foreign_key: true
    add_reference :plan_module_requirements, :plan_version, foreign_key: true

    say_with_time "Backfilling plan versions and linking existing data" do
      Plan.reset_column_information
      PlanVersion.reset_column_information
      ModuleGroup.reset_column_information
      PlanModule.reset_column_information
      PlanGeographicCoverArea.reset_column_information
      PlanResidencyEligibility.reset_column_information
      PlanModuleRequirement.reset_column_information
      CostShare.reset_column_information

      Plan.find_each do |plan|
        version = PlanVersion.create!(
          plan_id: plan.id,
          version_year: plan.version_year,
          children_only_allowed: plan.children_only_allowed,
          min_age: plan.min_age,
          max_age: plan.max_age,
          policy_type: plan.policy_type,
          published: plan.published,
          last_reviewed_at: plan.last_reviewed_at,
          next_review_due: plan.next_review_due,
          review_notes: plan.review_notes,
          current: true,
          created_at: plan.created_at,
          updated_at: plan.updated_at
        )

        ModuleGroup.where(plan_id: plan.id).update_all(plan_version_id: version.id)
        PlanModule.where(plan_id: plan.id).update_all(plan_version_id: version.id)
        PlanGeographicCoverArea.where(plan_id: plan.id).update_all(plan_version_id: version.id)
        PlanResidencyEligibility.where(plan_id: plan.id).update_all(plan_version_id: version.id)
        PlanModuleRequirement.where(plan_id: plan.id).update_all(plan_version_id: version.id)
        CostShare.where(scope_type: "Plan", scope_id: plan.id).update_all(scope_type: "PlanVersion", scope_id: version.id)
      end
    end

    change_column_null :module_groups, :plan_version_id, false
    change_column_null :plan_modules, :plan_version_id, false
    change_column_null :plan_geographic_cover_areas, :plan_version_id, false
    change_column_null :plan_residency_eligibilities, :plan_version_id, false
    change_column_null :plan_module_requirements, :plan_version_id, false

    remove_index :plan_module_requirements, name: "idx_pmr_plan_module_requires_unique"
    add_index :plan_module_requirements,
              [ :plan_version_id, :dependent_module_id, :required_module_id ],
              unique: true,
              name: "idx_pmr_plan_version_module_requires_unique"

    remove_reference :module_groups, :plan, foreign_key: true
    remove_reference :plan_modules, :plan, foreign_key: true
    remove_reference :plan_geographic_cover_areas, :plan, foreign_key: true
    remove_reference :plan_residency_eligibilities, :plan, foreign_key: true
    remove_reference :plan_module_requirements, :plan, foreign_key: true

    remove_columns :plans,
                   :version_year,
                   :children_only_allowed,
                   :min_age,
                   :max_age,
                   :policy_type,
                   :published,
                   :last_reviewed_at,
                   :next_review_due,
                   :review_notes
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Plan versions migration cannot be automatically reversed"
  end
end
