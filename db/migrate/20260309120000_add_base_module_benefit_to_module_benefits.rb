class AddBaseModuleBenefitToModuleBenefits < ActiveRecord::Migration[8.1]
  def change
    add_reference :module_benefits,
                  :base_module_benefit,
                  foreign_key: { to_table: :module_benefits },
                  index: true,
                  null: true
  end
end
