class PlanVersionDuplicator
  def self.call(plan_version)
    new(plan_version).call
  end

  def initialize(plan_version)
    @plan_version = plan_version
  end

  def call
    raise ArgumentError, "Plan version is required" if plan_version.nil?

    PlanVersion.transaction do
      duplicate_plan_version
    end
  end

  private

  attr_reader :plan_version

  def duplicate_plan_version
    new_version = plan_version.plan.plan_versions.create!(plan_version_attributes)

    copy_plan_geographic_cover_areas(new_version)
    copy_plan_residency_eligibilities(new_version)

    module_group_map = copy_module_groups(new_version)
    plan_module_map = copy_plan_modules(new_version, module_group_map)
    benefit_limit_group_map = copy_benefit_limit_groups(plan_module_map)
    module_benefit_map = copy_module_benefits(plan_module_map, benefit_limit_group_map)
    cost_share_map = copy_cost_shares(new_version, plan_module_map, module_benefit_map, benefit_limit_group_map)

    copy_cost_share_links(cost_share_map)
    copy_plan_module_requirements(new_version, plan_module_map)

    new_version
  end

  def plan_version_attributes
    sanitized_attributes(plan_version).merge(current: false, published: false)
  end

  def copy_plan_geographic_cover_areas(new_version)
    plan_version.plan_geographic_cover_areas.find_each do |area|
      new_version.plan_geographic_cover_areas.create!(
        geographic_cover_area_id: area.geographic_cover_area_id
      )
    end
  end

  def copy_plan_residency_eligibilities(new_version)
    plan_version.plan_residency_eligibilities.find_each do |eligibility|
      new_version.plan_residency_eligibilities.create!(country_code: eligibility.country_code)
    end
  end

  def copy_module_groups(new_version)
    plan_version.module_groups.each_with_object({}) do |group, map|
      new_group = new_version.module_groups.create!(sanitized_attributes(group))
      map[group.id] = new_group
    end
  end

  def copy_plan_modules(new_version, module_group_map)
    plan_version.plan_modules.each_with_object({}) do |plan_module, map|
      new_group = module_group_map[plan_module.module_group_id]
      new_module = new_version.plan_modules.create!(
        sanitized_attributes(plan_module, %w[module_group_id]).merge(module_group: new_group)
      )
      new_module.coverage_category_ids = plan_module.coverage_category_ids
      map[plan_module.id] = new_module
    end
  end

  def copy_benefit_limit_groups(plan_module_map)
    plan_version.plan_modules.each_with_object({}) do |plan_module, map|
      new_module = plan_module_map[plan_module.id]
      plan_module.benefit_limit_groups.each do |group|
        new_group = new_module.benefit_limit_groups.create!(sanitized_attributes(group))
        map[group.id] = new_group
      end
    end
  end

  def copy_module_benefits(plan_module_map, benefit_limit_group_map)
    plan_version.plan_modules.each_with_object({}) do |plan_module, map|
      new_module = plan_module_map[plan_module.id]
      plan_module.module_benefits.each do |benefit|
        new_group = benefit_limit_group_map[benefit.benefit_limit_group_id]
        new_benefit = new_module.module_benefits.create!(
          sanitized_attributes(benefit, %w[benefit_limit_group_id]).merge(benefit_limit_group: new_group)
        )
        map[benefit.id] = new_benefit
      end
    end
  end

  def copy_cost_shares(new_version, plan_module_map, module_benefit_map, benefit_limit_group_map)
    cost_share_map = {}

    plan_version.cost_shares.find_each do |cost_share|
      cost_share_map[cost_share.id] =
        new_version.cost_shares.create!(sanitized_cost_share_attributes(cost_share).merge(scope: new_version))
    end

    plan_version.plan_modules.each do |plan_module|
      new_module = plan_module_map[plan_module.id]
      plan_module.cost_shares.each do |cost_share|
        cost_share_map[cost_share.id] =
          new_module.cost_shares.create!(sanitized_cost_share_attributes(cost_share).merge(scope: new_module))
      end

      plan_module.module_benefits.each do |benefit|
        new_benefit = module_benefit_map[benefit.id]
        benefit.cost_shares.each do |cost_share|
          cost_share_map[cost_share.id] =
            new_benefit.cost_shares.create!(sanitized_cost_share_attributes(cost_share).merge(scope: new_benefit))
        end
      end

      plan_module.benefit_limit_groups.each do |group|
        new_group = benefit_limit_group_map[group.id]
        group.cost_shares.each do |cost_share|
          cost_share_map[cost_share.id] =
            new_group.cost_shares.create!(sanitized_cost_share_attributes(cost_share).merge(scope: new_group))
        end
      end
    end

    cost_share_map
  end

  def copy_cost_share_links(cost_share_map)
    CostShareLink
      .where(cost_share_id: cost_share_map.keys, linked_cost_share_id: cost_share_map.keys)
      .find_each do |link|
        CostShareLink.create!(
          cost_share: cost_share_map[link.cost_share_id],
          linked_cost_share: cost_share_map[link.linked_cost_share_id],
          relationship_type: link.relationship_type
        )
      end
  end

  def copy_plan_module_requirements(new_version, plan_module_map)
    plan_version.plan_module_requirements.find_each do |requirement|
      new_version.plan_module_requirements.create!(
        dependent_module: plan_module_map[requirement.dependent_module_id],
        required_module: plan_module_map[requirement.required_module_id]
      )
    end
  end

  def sanitized_attributes(record, exclusions = [])
    record.attributes.except(
      "id",
      "created_at",
      "updated_at",
      "plan_version_id",
      "plan_module_id",
      *exclusions
    )
  end

  def sanitized_cost_share_attributes(cost_share)
    cost_share.attributes.except("id", "created_at", "updated_at", "scope_id", "scope_type")
  end
end
