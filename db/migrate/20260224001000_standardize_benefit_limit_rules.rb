class StandardizeBenefitLimitRules < ActiveRecord::Migration[8.1]
  class MigrationModuleBenefit < ApplicationRecord
    self.table_name = "module_benefits"
  end

  class MigrationBenefitLimitRule < ApplicationRecord
    self.table_name = "benefit_limit_rules"
  end

  def up
    rename_table :benefit_sub_limits, :benefit_limit_rules
    if index_name_exists?(:benefit_limit_rules, "index_benefit_sub_limits_on_module_benefit_id")
      rename_index :benefit_limit_rules,
                   "index_benefit_sub_limits_on_module_benefit_id",
                   "index_benefit_limit_rules_on_module_benefit_id"
    end

    rename_column :benefit_limit_rules, :limit_usd, :amount_usd
    rename_column :benefit_limit_rules, :limit_gbp, :amount_gbp
    rename_column :benefit_limit_rules, :limit_eur, :amount_eur

    add_column :benefit_limit_rules, :scope, :integer, null: false, default: 1
    add_column :benefit_limit_rules, :cap_usd, :decimal, precision: 12, scale: 2
    add_column :benefit_limit_rules, :cap_gbp, :decimal, precision: 12, scale: 2
    add_column :benefit_limit_rules, :cap_eur, :decimal, precision: 12, scale: 2
    add_column :benefit_limit_rules, :cap_unit, :string
    change_column_null :benefit_limit_rules, :name, true

    migrate_module_benefit_limits_to_rules

    remove_column :module_benefits, :limit_usd
    remove_column :module_benefits, :limit_gbp
    remove_column :module_benefits, :limit_eur
    remove_column :module_benefits, :limit_unit
    remove_column :module_benefits, :sub_limit_description
  end

  def down
    add_column :module_benefits, :limit_usd, :decimal, precision: 12, scale: 2
    add_column :module_benefits, :limit_gbp, :decimal, precision: 12, scale: 2
    add_column :module_benefits, :limit_eur, :decimal, precision: 12, scale: 2
    add_column :module_benefits, :limit_unit, :string
    add_column :module_benefits, :sub_limit_description, :string

    rename_column :benefit_limit_rules, :amount_usd, :limit_usd
    rename_column :benefit_limit_rules, :amount_gbp, :limit_gbp
    rename_column :benefit_limit_rules, :amount_eur, :limit_eur

    remove_column :benefit_limit_rules, :scope
    remove_column :benefit_limit_rules, :cap_usd
    remove_column :benefit_limit_rules, :cap_gbp
    remove_column :benefit_limit_rules, :cap_eur
    remove_column :benefit_limit_rules, :cap_unit
    change_column_null :benefit_limit_rules, :name, false

    if index_name_exists?(:benefit_limit_rules, "index_benefit_limit_rules_on_module_benefit_id")
      rename_index :benefit_limit_rules,
                   "index_benefit_limit_rules_on_module_benefit_id",
                   "index_benefit_sub_limits_on_module_benefit_id"
    end
    rename_table :benefit_limit_rules, :benefit_sub_limits
  end

  private

  def migrate_module_benefit_limits_to_rules
    MigrationModuleBenefit
      .where.not(limit_usd: nil)
      .or(MigrationModuleBenefit.where.not(limit_gbp: nil))
      .or(MigrationModuleBenefit.where.not(limit_eur: nil))
      .find_each do |module_benefit|
      MigrationBenefitLimitRule.create!(
        module_benefit_id: module_benefit.id,
        name: nil,
        scope: 0,
        limit_type: 0,
        amount_usd: module_benefit.limit_usd,
        amount_gbp: module_benefit.limit_gbp,
        amount_eur: module_benefit.limit_eur,
        unit: module_benefit.limit_unit,
        position: 0
      )
    end
  end
end
