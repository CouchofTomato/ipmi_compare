class CreatePlanResidencyEligibilities < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_residency_eligibilities do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.text :notes

      t.timestamps
    end
  end
end
