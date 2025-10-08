class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.references :insurer, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :min_age, null: false, default: 0
      t.integer :max_age
      t.boolean :children_only_allowed, null: false, default: false
      t.integer :version_year, null: false
      t.boolean :published, null: false, default: false
      t.integer :policy_type, null: false
      t.date :last_reviewed_at
      t.date :next_review_due, null: false
      t.text :review_notes

      t.timestamps
    end
  end
end
