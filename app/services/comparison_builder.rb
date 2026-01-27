class ComparisonBuilder
  def initialize(progress)
    @progress = progress
  end

  def build
    selections = normalized_plan_selections
    return empty_payload if selections.empty?

    plans_by_id =
      Plan.includes(:insurer, current_plan_version: { plan_modules: { module_benefits: [ :benefit, :benefit_limit_group ] } })
        .where(id: selections.map { |selection| selection["plan_id"] }.compact)
        .index_by(&:id)

    plan_versions = []
    selected_module_ids_by_plan_version = Hash.new { |hash, key| hash[key] = [] }

    selections.each do |selection|
      plan = plans_by_id[selection["plan_id"].to_i]
      next unless plan&.current_plan_version

      plan_version = plan.current_plan_version
      plan_versions << plan_version unless plan_versions.include?(plan_version)

      module_ids = selection.fetch("module_groups", {}).to_h.values.map(&:to_i).uniq
      selected_module_ids_by_plan_version[plan_version.id] |= module_ids
    end

    module_benefits_by_plan_version =
      plan_versions.index_with do |plan_version|
        selected_module_ids = selected_module_ids_by_plan_version[plan_version.id]
        modules = plan_version.plan_modules.select { |plan_module| selected_module_ids.include?(plan_module.id) }
        modules.flat_map(&:module_benefits)
      end

    categories =
      CoverageCategory.order(:position, :name).filter_map do |category|
        benefits = benefits_for_category(category, plan_versions, module_benefits_by_plan_version)
        next if benefits.empty?

        { id: category.id, name: category.name, benefits: benefits }
      end

    {
      plan_versions: plan_versions.map { |plan_version| plan_version_payload(plan_version) },
      categories: categories
    }
  end

  private

  attr_reader :progress

  def benefits_for_category(category, plan_versions, module_benefits_by_plan_version)
    benefits = {}

    plan_versions.each do |plan_version|
      module_benefits_by_plan_version[plan_version.id].each do |module_benefit|
        next unless module_benefit.benefit.coverage_category_id == category.id

        benefits[module_benefit.benefit_id] ||= module_benefit.benefit
      end
    end

    benefits.values.map do |benefit|
      {
        id: benefit.id,
        name: benefit.name,
        per_plan: plan_versions.index_with do |plan_version|
          module_benefit_entries(benefit.id, module_benefits_by_plan_version[plan_version.id])
        end
      }
    end
  end

  def module_benefit_entries(benefit_id, module_benefits)
    module_benefits
      .select { |module_benefit| module_benefit.benefit_id == benefit_id }
      .sort_by(&:weighting)
      .map do |module_benefit|
        {
          module_benefit_id: module_benefit.id,
          plan_module_id: module_benefit.plan_module_id,
          plan_module_name: module_benefit.plan_module.name,
          coverage_description: module_benefit.coverage_description,
          limit_usd: module_benefit.limit_usd,
          limit_gbp: module_benefit.limit_gbp,
          limit_eur: module_benefit.limit_eur,
          limit_unit: module_benefit.limit_unit,
          waiting_period_months: module_benefit.waiting_period_months,
          interaction_type: module_benefit.interaction_type,
          benefit_limit_group_name: module_benefit.benefit_limit_group&.name
        }
      end
  end

  def plan_version_payload(plan_version)
    {
      plan_version_id: plan_version.id,
      plan_id: plan_version.plan_id,
      plan_name: plan_version.plan.name,
      insurer_name: plan_version.plan.insurer.name,
      policy_type: plan_version.policy_type
    }
  end

  def normalized_plan_selections
    raw = progress.state["plan_selections"]
    case raw
    when Hash then raw.values
    when Array then raw
    else []
    end
  end

  def empty_payload
    { plan_versions: [], categories: [] }
  end
end
