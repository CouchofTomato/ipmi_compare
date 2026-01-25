class AddNameToWizardProgresses < ActiveRecord::Migration[7.1]
  def change
    add_column :wizard_progresses, :name, :string
  end
end
