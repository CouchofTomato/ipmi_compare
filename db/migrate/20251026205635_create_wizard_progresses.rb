class CreateWizardProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :wizard_progresses do |t|
      t.string :wizard_type, null: false
      t.references :entity, polymorphic: true, null: false
      t.string :current_step, null: false
      t.integer :step_order, null: false, default: 0
      t.string :status, null: false, default: "in_progress"
      t.datetime :started_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.datetime :last_interaction_at
      t.datetime :completed_at
      t.datetime :abandoned_at
      t.datetime :expires_at
      t.string :last_event
      t.integer :last_actor_id
      t.jsonb :metadata, null: false, default: {}
      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_foreign_key :wizard_progresses, :users, column: :last_actor_id

    add_index :wizard_progresses,
              %i[wizard_type entity_type entity_id],
              unique: true,
              name: "index_wizard_progresses_on_type_and_entity"
    add_index :wizard_progresses, %i[status updated_at]
    add_index :wizard_progresses, :wizard_type
  end
end
