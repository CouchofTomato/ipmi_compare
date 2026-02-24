require "rails_helper"

RSpec.describe PlanVersionDuplicator do
  describe ".call" do
    it "duplicates a plan version and its associations" do
      plan = create(:plan)
      source_version = plan.current_plan_version
      module_group = create(:module_group, plan_version: source_version, name: "Core", position: 1)
      coverage_category = create(:coverage_category)
      plan_module = create(:plan_module, plan_version: source_version, module_group: module_group, name: "Hospital module")
      plan_module.coverage_categories << coverage_category
      required_module = create(:plan_module, plan_version: source_version, module_group: module_group, name: "Optional module")
      create(:plan_module_requirement, plan_version: source_version, dependent_module: plan_module, required_module: required_module)
      benefit_limit_group = create(:benefit_limit_group, plan_module: plan_module)
      module_benefit = create(:module_benefit, plan_module: plan_module, benefit_limit_group: benefit_limit_group)
      benefit_limit_rule = create(:benefit_limit_rule, module_benefit: module_benefit, scope: :itemised, name: "MRI", limit_type: :amount, insurer_amount_usd: 1000, unit: "per examination", position: 0)

      create(:plan_residency_eligibility, plan_version: source_version, country_code: "US")
      create(:plan_geographic_cover_area, plan_version: source_version)

      plan_cost_share = create(:cost_share, scope: source_version, cost_share_type: :deductible, amount_usd: 100, per: :per_year)
      create(:cost_share, scope: plan_module, cost_share_type: :excess, amount_usd: 50, per: :per_condition)
      module_benefit_cost_share = create(:cost_share, scope: module_benefit, cost_share_type: :coinsurance, amount: 10, unit: :percent, per: :per_visit)
      create(:cost_share, scope: benefit_limit_rule, kind: :coinsurance, cost_share_type: :coinsurance, amount: 80, unit: :percent, per: :per_visit)
      create(:cost_share, scope: benefit_limit_group, cost_share_type: :excess, amount_usd: 75, per: :per_visit)
      create(:cost_share_link, cost_share: plan_cost_share, linked_cost_share: module_benefit_cost_share, relationship_type: :shared_pool)

      new_version = described_class.call(source_version)

      expect(new_version).to be_persisted
      expect(new_version).not_to be_current
      expect(new_version).not_to be_published
      expect(new_version.plan).to eq(plan)

      expect(new_version.module_groups.count).to eq(1)
      expect(new_version.plan_modules.count).to eq(2)
      expect(new_version.plan_module_requirements.count).to eq(1)
      expect(new_version.plan_module_requirements.first.dependent_module.plan_version).to eq(new_version)
      expect(new_version.plan_module_requirements.first.required_module.plan_version).to eq(new_version)
      expect(new_version.plan_residency_eligibilities.pluck(:country_code)).to contain_exactly("US")
      expect(new_version.plan_geographic_cover_areas.count).to eq(1)

      new_module = new_version.plan_modules.find_by(name: "Hospital module")
      expect(new_module.coverage_category_ids).to contain_exactly(coverage_category.id)
      expect(new_module.benefit_limit_groups.count).to eq(1)
      expect(new_module.module_benefits.count).to eq(1)
      expect(new_module.module_benefits.first.benefit_limit_group).to eq(new_module.benefit_limit_groups.first)
      expect(new_module.module_benefits.first.benefit_limit_rules.pluck(:name)).to eq([ "MRI" ])

      plan_scope_cost_shares = new_version.cost_shares.pluck(:id)
      module_scope_cost_shares = CostShare.where(scope_type: "PlanModule", scope_id: new_version.plan_module_ids).pluck(:id)
      module_benefit_scope_cost_shares = CostShare.where(scope_type: "ModuleBenefit", scope_id: new_module.module_benefits.pluck(:id)).pluck(:id)
      benefit_limit_rule_scope_cost_shares = CostShare.where(scope_type: "BenefitLimitRule", scope_id: new_module.module_benefits.flat_map { |benefit| benefit.benefit_limit_rules.pluck(:id) }).pluck(:id)
      benefit_limit_group_scope_cost_shares = CostShare.where(scope_type: "BenefitLimitGroup", scope_id: new_module.benefit_limit_groups.pluck(:id)).pluck(:id)

      expect(plan_scope_cost_shares.count).to eq(1)
      expect(module_scope_cost_shares.count).to eq(1)
      expect(module_benefit_scope_cost_shares.count).to eq(1)
      expect(benefit_limit_rule_scope_cost_shares.count).to eq(1)
      expect(benefit_limit_group_scope_cost_shares.count).to eq(1)

      all_new_cost_share_ids = plan_scope_cost_shares + module_scope_cost_shares + module_benefit_scope_cost_shares + benefit_limit_rule_scope_cost_shares + benefit_limit_group_scope_cost_shares
      links = CostShareLink.where(cost_share_id: all_new_cost_share_ids, linked_cost_share_id: all_new_cost_share_ids)
      expect(links.count).to eq(1)
    end
  end
end
