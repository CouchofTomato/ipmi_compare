class AddStateToWizardProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :wizard_progresses, :state, :jsonb, default: {}, null: false
  end
end
