class BackfillBenefitLimitGroupRules < ActiveRecord::Migration[8.1]
  class MigrationBenefitLimitGroup < ApplicationRecord
    self.table_name = "benefit_limit_groups"
  end

  class MigrationBenefitLimitGroupRule < ApplicationRecord
    self.table_name = "benefit_limit_group_rules"
  end

  def up
    MigrationBenefitLimitGroup.find_each do |group|
      next unless legacy_limit_present?(group)
      next if MigrationBenefitLimitGroupRule.where(benefit_limit_group_id: group.id).exists?

      MigrationBenefitLimitGroupRule.create!(
        benefit_limit_group_id: group.id,
        rule_type: 0, # amount
        amount_usd: group.limit_usd,
        amount_gbp: group.limit_gbp,
        amount_eur: group.limit_eur,
        period_kind: period_kind_for(group.limit_unit),
        period_value: period_value_for(group.limit_unit),
        position: 0,
        notes: group.notes
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Backfilled benefit limit group rules cannot be safely removed"
  end

  private

  def legacy_limit_present?(group)
    [ group.limit_usd, group.limit_gbp, group.limit_eur ].any?(&:present?)
  end

  def period_kind_for(limit_unit)
    normalized = limit_unit.to_s.downcase
    return 2 if normalized.match?(/(\d+).*(day|days)/)
    return 3 if normalized.match?(/(\d+).*(month|months)/)
    return 1 if normalized.include?("calendar")
    return 4 if normalized.include?("lifetime")

    0
  end

  def period_value_for(limit_unit)
    normalized = limit_unit.to_s.downcase
    return unless normalized.match?(/(\d+)/)
    return unless normalized.include?("day") || normalized.include?("month")

    normalized.match(/(\d+)/)[1].to_i
  end
end
