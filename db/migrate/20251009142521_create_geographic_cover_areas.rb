class CreateGeographicCoverAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :geographic_cover_areas do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
  end
end
