class UpdateModuleGroupPositionDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :module_groups, :position, 0
    change_column_null :module_groups, :position, false
  end
end
