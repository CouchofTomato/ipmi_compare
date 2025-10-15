class CreateModuleBenefits < ActiveRecord::Migration[8.0]
  def change
    create_table :module_benefits do |t|
      t.references :plan_module, null: false, foreign_key: true
      t.references :benefit, null: false, foreign_key: true
      t.string :coverage_description, null: true
      t.decimal :limit_usd, precision: 12, scale: 2, null: true
      t.decimal :limit_gbp, precision: 12, scale: 2, null: true
      t.decimal :limit_eur, precision: 12, scale: 2, null: true
      t.string :limit_unit, null: true
      t.string :sub_limit_description, null: true
      t.references :benefit_limit_group, null: true, foreign_key: true

      t.timestamps
    end
  end
end
