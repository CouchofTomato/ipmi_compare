class AddInteractionTypeAndWeightingToModuleBenefits < ActiveRecord::Migration[8.0]
  def change
    add_column :module_benefits, :interaction_type, :integer, null: false, default: 1
    add_column :module_benefits, :weighting, :integer, null: false, default: 0

    add_index :module_benefits, :interaction_type
    add_index :module_benefits, :weighting
  end
end
