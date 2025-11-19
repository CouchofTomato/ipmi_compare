class CreateCoverageCategoriesPlanModulesJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_join_table :plan_modules, :coverage_categories, column_options: { null: false, foreign_key: true } do |t|
    end

    add_index :coverage_categories_plan_modules, [ :plan_module_id, :coverage_category_id ],
              name: "idx_ccpm_unique", unique: true
  end
end
