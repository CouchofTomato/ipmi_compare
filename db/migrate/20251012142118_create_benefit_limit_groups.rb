class CreateBenefitLimitGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :benefit_limit_groups do |t|
      t.references :plan_module, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :limit_usd, precision: 12, scale: 2, null: true
      t.decimal :limit_gbp, precision: 12, scale: 2, null: true
      t.decimal :limit_eur, precision: 12, scale: 2, null: true
      t.string :limit_unit, null: false
      t.text :notes

      t.timestamps
    end
  end
end
