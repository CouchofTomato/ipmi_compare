class CreatePlanGeographicCoverAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :plan_geographic_cover_areas do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :geographic_cover_area, null: false, foreign_key: true

      t.timestamps
    end
  end
end
