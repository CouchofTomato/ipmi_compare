class AddOverallLimitsToPlanModules < ActiveRecord::Migration[8.0]
  def change
    add_column :plan_modules, :overall_limit_usd, :decimal, precision: 12, scale: 2, null: true
    add_column :plan_modules, :overall_limit_gbp, :decimal, precision: 12, scale: 2, null: true
    add_column :plan_modules, :overall_limit_eur, :decimal, precision: 12, scale: 2, null: true
    add_column :plan_modules, :overall_limit_unit, :string, null: true
    add_column :plan_modules, :overall_limit_notes, :text, null: true
  end
end
