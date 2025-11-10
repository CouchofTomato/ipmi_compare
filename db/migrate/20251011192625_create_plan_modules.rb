class CreatePlanModules < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_modules do |t|
      t.references :plan, null: false, foreign_key: true
      t.string :name, null: false
      t.boolean :is_core, null: false, default: false
      t.references :module_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
