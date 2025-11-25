class AddPlanAndPositionToModuleGroups < ActiveRecord::Migration[8.1]
  def change
    add_reference :module_groups, :plan, null: false, foreign_key: true
    add_column :module_groups, :position, :integer
  end
end
