class CreatePlanModuleRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_module_requirements do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :dependent_module, null: false, foreign_key: { to_table: :plan_modules }
      t.references :required_module, null: false, foreign_key: { to_table: :plan_modules }

      t.timestamps
    end

    add_index :plan_module_requirements,
          [ :plan_id, :dependent_module_id, :required_module_id ],
          unique: true,
          name: "idx_pmr_plan_module_requires_unique"
  end
end
