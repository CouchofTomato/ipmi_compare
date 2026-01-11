class AddWaitingPeriodMonthsToModuleBenefits < ActiveRecord::Migration[8.1]
  def change
    add_column :module_benefits, :waiting_period_months, :integer
  end
end
