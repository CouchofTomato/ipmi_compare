class PlanWizardFlow
  attr_reader :progress

  def initialize(progress)
    @progress = progress
  end

  def steps
    %w[
      plan_details
      plan_residency
      geographic_cover_areas
      module_groups
      plan_modules
      plan_module_requirements
      module_benefits
      benefit_limit_groups
      cost_shares
      cost_share_links
      review
    ]
  end

  def handle_step(params)
    case progress.current_step
    when "plan_details" then save_plan_details(params[:plan])
    when "plan_residency" then save_plan_residency(params[:residency])
    when "geographic_cover_areas" then save_geographic_cover_areas(params[:areas])
    when "module_groups" then save_module_groups(params[:module_groups], params[:step_action])
    when "plan_modules"       then save_plan_modules(params[:modules], params[:step_action])
    when "plan_module_requirements" then save_plan_module_requirements(params[:requirements], params[:step_action])
    when "module_benefits"      then save_module_benefits(params[:benefits], params[:step_action])
    when "benefit_limit_groups" then save_benefit_limit_groups(params[:benefit_limit_groups], params[:step_action])
    when "cost_shares"   then save_cost_shares(params[:cost_shares], params[:step_action])
    when "cost_share_links" then save_cost_share_links(params[:cost_share_links], params[:step_action])
    when "review"        then save_review(params[:review], params[:step_action])
    else
      WizardStepResult.new(success: true)
    end
  end

  def presenter_for(current_step)
    nil
  end

  def save_plan_details(plan_params)
    raise ActionController::ParameterMissing, :plan if plan_params.nil?
    plan = progress.subject || Plan.new
    permitted =
      plan_params.permit(
        :insurer_id,
        :name,
        :min_age,
        :max_age,
        :children_only_allowed,
        :version_year,
        :effective_on,
        :effective_through,
        :published,
        :policy_type,
        :last_reviewed_at,
        :next_review_due,
        :review_notes,
        :overall_limit_usd,
        :overall_limit_gbp,
        :overall_limit_eur,
        :overall_limit_unit,
        :overall_limit_notes,
        :overall_limit_unlimited
      )

    explicit_version = explicit_plan_version_for(plan)
    if plan.persisted? && explicit_version.present?
      plan.assign_attributes(permitted.slice(:insurer_id, :name))
      explicit_version.assign_attributes(permitted.except(:insurer_id, :name))
    else
      plan.assign_attributes(permitted)
    end

    errors = nil

    ActiveRecord::Base.transaction do
      unless plan.save
        errors = plan.errors.full_messages
        raise ActiveRecord::Rollback
      end

      if plan.persisted? && explicit_version.present?
        unless explicit_version.save
          explicit_version.errors.each do |error|
            plan.errors.add(error.attribute, error.message)
          end
          errors = plan.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end

      progress.update!(subject: plan)
    end

    if errors
      WizardStepResult.new(success: false, resource: plan, errors: errors)
    else
      WizardStepResult.new(success: true, resource: plan)
    end
  end

  def save_plan_residency(residency_params)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before setting residency eligibility" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_residency = residency_params.is_a?(ActionController::Parameters) ? residency_params : ActionController::Parameters.new
    permitted = params_for_residency.permit(country_codes: [])
    country_codes = Array(permitted[:country_codes])
      .map { |code| code.to_s.strip.upcase }
      .reject(&:blank?)
      .uniq

    valid_codes = ISO3166::Country.all.map(&:alpha2)
    invalid_codes = country_codes - valid_codes

    if invalid_codes.any?
      invalid_codes.each do |code|
        plan.errors.add(:base, "#{code} is not a valid ISO country code")
      end
      return WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
    end

    ActiveRecord::Base.transaction do
      plan_version.plan_residency_eligibilities.where.not(country_code: country_codes).destroy_all
      country_codes.each do |code|
        plan_version.plan_residency_eligibilities.find_or_create_by!(country_code: code)
      end
    end

    plan_version.plan_residency_eligibilities.reload

    WizardStepResult.new(success: true, resource: plan)
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each do |attribute, message|
      plan.errors.add(attribute, message)
    end
    WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages.presence || [ "Could not update residency eligibility" ])
  end

  def save_geographic_cover_areas(areas_params)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before selecting geographic cover areas" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_areas =
      case areas_params
      when ActionController::Parameters then areas_params
      when Hash then ActionController::Parameters.new(areas_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_areas.permit(geographic_cover_area_ids: [], area_ids: [])
    raw_ids = Array(permitted[:geographic_cover_area_ids]) + Array(permitted[:area_ids])
    raw_ids = raw_ids.map { |value| value.to_s.strip }.reject(&:blank?)

    sanitized_ids = []
    invalid_inputs = []

    raw_ids.each do |value|
      begin
        sanitized_ids << Integer(value)
      rescue ArgumentError, TypeError
        invalid_inputs << value
      end
    end

    if invalid_inputs.any?
      invalid_inputs.each do |value|
        plan.errors.add(:base, "#{value} is not a valid geographic cover area id")
      end
      return WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
    end

    sanitized_ids.uniq!
    existing_ids = GeographicCoverArea.where(id: sanitized_ids).pluck(:id)
    missing_ids = sanitized_ids - existing_ids

    if missing_ids.any?
      missing_ids.each do |value|
        plan.errors.add(:base, "Geographic cover area #{value} could not be found")
      end
      return WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
    end

    ActiveRecord::Base.transaction do
      if existing_ids.empty?
        plan_version.plan_geographic_cover_areas.destroy_all
      else
        plan_version.plan_geographic_cover_areas.where.not(geographic_cover_area_id: existing_ids).destroy_all
        existing_ids.each do |area_id|
          plan_version.plan_geographic_cover_areas.find_or_create_by!(geographic_cover_area_id: area_id)
        end
      end
    end

    plan_version.plan_geographic_cover_areas.reload
    plan_version.geographic_cover_areas.reset

    WizardStepResult.new(success: true, resource: plan)
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each do |attribute, message|
      plan.errors.add(attribute, message)
    end
    WizardStepResult.new(
      success: false,
      resource: plan,
      errors: plan.errors.full_messages.presence || [ "Could not update geographic cover areas" ]
    )
  end

  def save_module_groups(module_group_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding module groups" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_group =
      case module_group_params
      when ActionController::Parameters then module_group_params
      when Hash then ActionController::Parameters.new(module_group_params)
      else
        ActionController::Parameters.new
      end

    if step_action == "delete"
      group_id = params_for_group[:id].presence || params_for_group[:module_group_id].presence
      group_id = Integer(group_id) rescue nil
      module_group = plan_version.module_groups.find_by(id: group_id)

      if module_group.nil?
        module_group = ModuleGroup.new
        module_group.errors.add(:base, "Module group not found")
        return WizardStepResult.new(success: false, resource: module_group, errors: module_group.errors.full_messages)
      end

      module_group.destroy
      plan_version.module_groups.reload

      return WizardStepResult.new(success: true, resource: plan)
    end

    # Only attempt to create a new module group when explicitly asked
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    permitted = params_for_group.permit(:name, :description, :position)
    sanitized_values = permitted.to_h

    module_group = plan_version.module_groups.build(sanitized_values)
    module_group.position ||= plan_version.module_groups.maximum(:position).to_i + 1

    if sanitized_values["name"].to_s.strip.blank?
      module_group.validate
      module_group.errors.add(:name, "can't be blank") if module_group.errors[:name].blank?
      return WizardStepResult.new(success: false, resource: module_group, errors: module_group.errors.full_messages)
    end

    if module_group.save
      plan_version.module_groups.reload
      WizardStepResult.new(success: true, resource: module_group)
    else
      WizardStepResult.new(success: false, resource: module_group, errors: module_group.errors.full_messages)
    end
  end

  def save_plan_modules(module_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding plan modules" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_module =
      case module_params
      when ActionController::Parameters then module_params
      when Hash then ActionController::Parameters.new(module_params)
      else
        ActionController::Parameters.new
      end

    if step_action == "delete"
      module_id = params_for_module[:id].presence || params_for_module[:plan_module_id].presence
      module_id = Integer(module_id) rescue nil
      plan_module = plan_version.plan_modules.find_by(id: module_id)

      if plan_module.nil?
        plan_module = PlanModule.new(plan:)
        plan_module.errors.add(:base, "Plan module not found")
        return WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
      end

      plan_module.destroy
      plan_version.plan_modules.reload

      return WizardStepResult.new(success: true, resource: plan)
    end

    # Only create a new module when explicitly requested
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    permitted = params_for_module.permit(:name,
                                         :module_group_id,
                                         :is_core,
                                         :overall_limit_usd,
                                         :overall_limit_gbp,
                                         :overall_limit_eur,
                                         :overall_limit_unit,
                                         :overall_limit_notes,
                                         :overall_limit_usd,
                                         :overall_limit_gbp,
                                         :overall_limit_eur,
                                         :overall_limit_unit,
                                         :overall_limit_notes,
                                         coverage_category_ids: [])
    sanitized_values = permitted.to_h
    sanitized_values["is_core"] = ActiveModel::Type::Boolean.new.cast(sanitized_values["is_core"])

    plan_module = plan_version.plan_modules.build(sanitized_values)
    raw_category_ids = Array(permitted[:coverage_category_ids])
    category_ids = []
    invalid_category_inputs = []

    raw_category_ids.each do |value|
      next if value.blank?

      begin
        category_ids << Integer(value)
      rescue ArgumentError, TypeError
        invalid_category_inputs << value
      end
    end

    if invalid_category_inputs.any?
      plan_module.errors.add(:coverage_categories, "contain invalid selections")
      return WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end

    category_ids.uniq!
    existing_category_ids = CoverageCategory.where(id: category_ids).pluck(:id)
    missing_category_ids = category_ids - existing_category_ids

    if missing_category_ids.any?
      missing_category_ids.each do |value|
        plan_module.errors.add(:coverage_categories, "selection #{value} could not be found")
      end
      return WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end

    plan_module.coverage_category_ids = existing_category_ids

    # Guard against selecting a module group from another plan
    if plan_module.module_group_id.present? && !plan_version.module_groups.exists?(id: plan_module.module_group_id)
      plan_module.errors.add(:module_group, "must belong to this plan")
      return WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end

    if plan_module.save
      plan_version.plan_modules.reload
      WizardStepResult.new(success: true, resource: plan_module)
    else
      WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end
  end

  def save_plan_module_requirements(requirements_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding module requirements" ]) unless plan.present?

    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_requirements =
      case requirements_params
      when ActionController::Parameters then requirements_params
      when Hash then ActionController::Parameters.new(requirements_params)
      else
        ActionController::Parameters.new
      end

    raw_requirements =
      params_for_requirements[:requirements] ||
      params_for_requirements["requirements"] ||
      params_for_requirements

    raw_requirements = raw_requirements.to_unsafe_h if raw_requirements.respond_to?(:to_unsafe_h)
    raw_requirements ||= {}

    plan_modules = plan_version.plan_modules.index_by(&:id)
    allowed_ids = plan_modules.keys

    normalized = {}
    raw_requirements.each do |dependent_id, required_ids|
      dep_id = Integer(dependent_id) rescue nil
      next unless dep_id && allowed_ids.include?(dep_id)

      req_ids = Array(required_ids).map { |value| Integer(value) rescue nil }.compact.uniq
      normalized[dep_id] = req_ids & allowed_ids
    end

    errors = []
    failing_requirement = nil

    ActiveRecord::Base.transaction do
      PlanModuleRequirement.where(plan_version: plan_version).delete_all

      normalized.each do |dep_id, req_ids|
        req_ids.each do |req_id|
          next if dep_id == req_id

          requirement = PlanModuleRequirement.new(
            plan_version: plan_version,
            dependent_module_id: dep_id,
            required_module_id: req_id
          )

          unless requirement.save
            errors.concat(requirement.errors.full_messages)
            failing_requirement ||= requirement
            raise ActiveRecord::Rollback
          end
        end
      end
    end

    if errors.any?
      WizardStepResult.new(success: false, resource: failing_requirement, errors: errors.presence || [ "Could not save module requirements" ])
    else
      WizardStepResult.new(success: true, resource: plan)
    end
  rescue ActiveRecord::RecordInvalid => e
    WizardStepResult.new(success: false, resource: e.record, errors: e.record.errors.full_messages.presence || [ "Could not save module requirements" ])
  end

  def save_module_benefits(benefit_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding module benefits" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_benefit =
      case benefit_params
      when ActionController::Parameters then benefit_params
      when Hash then ActionController::Parameters.new(benefit_params)
      else
        ActionController::Parameters.new
      end

    if step_action == "edit"
      benefit_id = params_for_benefit[:id].presence || params_for_benefit[:module_benefit_id].presence
      benefit_id = Integer(benefit_id) rescue nil
      module_benefit = ModuleBenefit.where(plan_module_id: plan_version.plan_module_ids).includes(:benefit_limit_rules).find_by(id: benefit_id)

      if module_benefit.nil?
        module_benefit = ModuleBenefit.new
        module_benefit.errors.add(:base, "Module benefit not found")
        return WizardStepResult.new(success: false, resource: module_benefit, errors: module_benefit.errors.full_messages)
      end

      return WizardStepResult.new(success: true, resource: module_benefit)
    end

    if step_action == "delete"
      benefit_id = params_for_benefit[:id].presence || params_for_benefit[:module_benefit_id].presence
      benefit_id = Integer(benefit_id) rescue nil
      module_benefit = ModuleBenefit.where(plan_module_id: plan_version.plan_module_ids).find_by(id: benefit_id)

      if module_benefit.nil?
        module_benefit = ModuleBenefit.new
        module_benefit.errors.add(:base, "Module benefit not found")
        return WizardStepResult.new(success: false, resource: module_benefit, errors: module_benefit.errors.full_messages)
      end

      module_benefit.destroy
      plan_version.plan_modules.includes(:module_benefits).each { |pm| pm.module_benefits.reset }

      return WizardStepResult.new(success: true, resource: plan)
    end

    # Only create a new module benefit when explicitly asked
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    permitted = params_for_benefit.permit(
      :id,
      :plan_module_id,
      :benefit_id,
      :coverage_description,
      :waiting_period_months,
      :interaction_type,
      :weighting,
      benefit_limit_rules_attributes: [
        :id,
        :name,
        :scope,
        :limit_type,
        :insurer_amount_usd,
        :insurer_amount_gbp,
        :insurer_amount_eur,
        :unit,
        :cap_insurer_amount_usd,
        :cap_insurer_amount_gbp,
        :cap_insurer_amount_eur,
        :cap_unit,
        :notes,
        :position,
        :_destroy
      ]
    )

    module_benefit_id = permitted[:id].presence
    sanitized_values = permitted.to_h
    sanitized_values["weighting"] = sanitized_values["weighting"].presence
    sanitized_values.delete("weighting") if sanitized_values["weighting"].nil?
    sanitized_values.delete("id")

    plan_module = plan_version.plan_modules.find_by(id: sanitized_values["plan_module_id"])

    unless plan_module
      module_benefit = ModuleBenefit.new
      module_benefit.errors.add(:plan_module, "must belong to this plan")
      return WizardStepResult.new(success: false, resource: module_benefit, errors: module_benefit.errors.full_messages)
    end

    module_benefit =
      if module_benefit_id
        ModuleBenefit.where(plan_module_id: plan_version.plan_module_ids).find_by(id: module_benefit_id)
      else
        ModuleBenefit.new
      end

    unless module_benefit
      missing_module_benefit = ModuleBenefit.new
      missing_module_benefit.errors.add(:base, "Module benefit not found")
      return WizardStepResult.new(success: false, resource: missing_module_benefit, errors: missing_module_benefit.errors.full_messages)
    end

    module_benefit.assign_attributes(sanitized_values.merge(plan_module:))

    # default weighting to next available slot if not provided
    if module_benefit.weighting.nil? && module_benefit.new_record?
      max_weighting = ModuleBenefit.where(plan_module_id: plan_version.plan_module_ids).maximum(:weighting)
      module_benefit.weighting = max_weighting ? max_weighting + 1 : 0
    end

    if module_benefit.save
      plan_module.module_benefits.reload
      WizardStepResult.new(success: true, resource: module_benefit)
    else
      WizardStepResult.new(success: false, resource: module_benefit, errors: module_benefit.errors.full_messages)
    end
  end

  def save_benefit_limit_groups(group_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding benefit limit groups" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_group =
      case group_params
      when ActionController::Parameters then group_params
      when Hash then ActionController::Parameters.new(group_params)
      else
        ActionController::Parameters.new
      end

    if step_action == "delete"
      group_id = params_for_group[:id].presence || params_for_group[:benefit_limit_group_id].presence
      group_id = Integer(group_id) rescue nil
      benefit_limit_group = BenefitLimitGroup.where(plan_module_id: plan_version.plan_module_ids).find_by(id: group_id)

      if benefit_limit_group.nil?
        benefit_limit_group = BenefitLimitGroup.new
        benefit_limit_group.errors.add(:base, "Benefit limit group not found")
        return WizardStepResult.new(success: false, resource: benefit_limit_group, errors: benefit_limit_group.errors.full_messages)
      end

      benefit_limit_group.destroy
      plan_version.plan_modules.includes(:benefit_limit_groups).each { |pm| pm.benefit_limit_groups.reset }

      return WizardStepResult.new(success: true, resource: plan)
    end

    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    permitted = params_for_group.permit(:plan_module_id,
                                        :name,
                                        :limit_usd,
                                        :limit_gbp,
                                        :limit_eur,
                                        :limit_unit,
                                        :notes,
                                        module_benefit_ids: [])

    sanitized_values = permitted.to_h
    module_benefit_ids =
      Array(permitted[:module_benefit_ids])
        .map { |id| id.presence }
        .map { |id| Integer(id) rescue nil }
        .compact
        .uniq

    plan_module = plan_version.plan_modules.find_by(id: sanitized_values["plan_module_id"])
    unless plan_module
      benefit_limit_group = BenefitLimitGroup.new
      benefit_limit_group.module_benefit_ids = module_benefit_ids
      benefit_limit_group.errors.add(:plan_module, "must belong to this plan")
      return WizardStepResult.new(success: false, resource: benefit_limit_group, errors: benefit_limit_group.errors.full_messages)
    end

    selected_module_benefit_ids = plan_module.module_benefits.where(id: module_benefit_ids).pluck(:id)
    benefit_limit_group = plan_module.benefit_limit_groups.new(sanitized_values.except("module_benefit_ids"))
    benefit_limit_group.module_benefit_ids = selected_module_benefit_ids

    if benefit_limit_group.save
      ModuleBenefit.where(id: selected_module_benefit_ids).update_all(benefit_limit_group_id: benefit_limit_group.id) if selected_module_benefit_ids.any?
      plan_module.module_benefits.reload
      WizardStepResult.new(success: true, resource: benefit_limit_group)
    else
      WizardStepResult.new(success: false, resource: benefit_limit_group, errors: benefit_limit_group.errors.full_messages)
    end
  end

  def save_cost_shares(cost_share_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding cost shares" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_cost_share =
      case cost_share_params
      when ActionController::Parameters then cost_share_params
      when Hash then ActionController::Parameters.new(cost_share_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_cost_share.permit(:applies_to,
                                             :plan_module_id,
                                             :module_benefit_id,
                                             :benefit_limit_group_id,
                                             :cost_share_type,
                                             :amount,
                                             :unit,
                                             :per,
                                             :currency,
                                             :notes,
                                             :id)

    sanitized = permitted.to_h
    # Only treat this submission as a create when meaningful fields are present.
    if step_action == "delete"
      cost_share_id = permitted[:id].presence || params_for_cost_share[:cost_share_id].presence
      cost_share_id = Integer(cost_share_id) rescue nil
      cost_share = CostShare.find_by(id: cost_share_id)

      allowed_ids = cost_share_ids_for_plan(plan_version)
      unless cost_share && allowed_ids.include?(cost_share.id)
        cost_share = CostShare.new
        cost_share.errors.add(:base, "Cost share not found")
        return WizardStepResult.new(success: false, resource: cost_share, errors: cost_share.errors.full_messages)
      end

      cost_share.destroy
      plan_version.cost_shares.reset
      plan_version.plan_modules.each { |pm| pm.cost_shares.reset }

      return WizardStepResult.new(success: true, resource: plan)
    end

    user_filled_any = sanitized.slice("amount", "currency", "notes", "plan_module_id", "module_benefit_id", "benefit_limit_group_id").values.any?(&:present?)
    creating = step_action.in?([ "add", "next" ]) || (step_action.blank? && user_filled_any)

    return WizardStepResult.new(success: true, resource: plan) unless creating && user_filled_any

    applies_to = permitted[:applies_to].presence || "plan"
    plan_module_id = permitted[:plan_module_id].presence
    module_benefit_id = permitted[:module_benefit_id].presence
    benefit_limit_group_id = permitted[:benefit_limit_group_id].presence

    scope =
      case applies_to
      when "plan"
        plan_version
      when "plan_module"
        plan_version.plan_modules.find_by(id: plan_module_id)
      when "module_benefit"
        ModuleBenefit.where(plan_module_id: plan_version.plan_module_ids).find_by(id: module_benefit_id)
      when "benefit_limit_group"
        BenefitLimitGroup.where(plan_module_id: plan_version.plan_module_ids).find_by(id: benefit_limit_group_id)
      else
        nil
      end

    cost_share = CostShare.new(permitted.except(:applies_to, :plan_module_id, :module_benefit_id, :benefit_limit_group_id).merge(scope:))
    cost_share.applies_to = applies_to
    cost_share.plan_module_id = plan_module_id
    cost_share.module_benefit_id = module_benefit_id
    cost_share.benefit_limit_group_id = benefit_limit_group_id

    if scope.nil?
      cost_share.errors.add(:base, "Select where this cost share applies")
      return WizardStepResult.new(success: false, resource: cost_share, errors: cost_share.errors.full_messages)
    end

    if cost_share.save
      scope.cost_shares.reload if scope.respond_to?(:cost_shares)
      WizardStepResult.new(success: true, resource: cost_share)
    else
      WizardStepResult.new(success: false, resource: cost_share, errors: cost_share.errors.full_messages)
    end
  end

  def save_cost_share_links(cost_share_link_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before linking cost shares" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    params_for_cost_share_link =
      case cost_share_link_params
      when ActionController::Parameters then cost_share_link_params
      when Hash then ActionController::Parameters.new(cost_share_link_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_cost_share_link.permit(:cost_share_id, :linked_cost_share_id, :relationship_type, :id)
    sanitized = permitted.to_h

    if step_action == "delete"
      link_id = permitted[:id].presence || params_for_cost_share_link[:cost_share_link_id].presence
      link_id = Integer(link_id) rescue nil
      allowed_ids = cost_share_ids_for_plan(plan_version)
      cost_share_link = CostShareLink.find_by(id: link_id)

      unless cost_share_link && allowed_ids.include?(cost_share_link.cost_share_id) && allowed_ids.include?(cost_share_link.linked_cost_share_id)
        cost_share_link = CostShareLink.new
        cost_share_link.errors.add(:base, "Cost share link not found")
        return WizardStepResult.new(success: false, resource: cost_share_link, errors: cost_share_link.errors.full_messages)
      end

      cost_share_link.destroy
      return WizardStepResult.new(success: true, resource: plan)
    end

    user_filled_any = sanitized.values.any?(&:present?)
    creating = step_action.in?([ "add", "next" ]) || (step_action.blank? && user_filled_any)
    return WizardStepResult.new(success: true, resource: plan) unless creating && user_filled_any

    cost_share_link = CostShareLink.new(relationship_type: permitted[:relationship_type])
    allowed_cost_share_ids = cost_share_ids_for_plan(plan_version)

    cost_share = CostShare.find_by(id: permitted[:cost_share_id])
    linked_cost_share = CostShare.find_by(id: permitted[:linked_cost_share_id])

    if permitted[:cost_share_id].blank? || cost_share.nil? || !allowed_cost_share_ids.include?(cost_share.id)
      cost_share_link.errors.add(:cost_share, "must be selected from this plan")
    else
      cost_share_link.cost_share = cost_share
    end

    if permitted[:linked_cost_share_id].blank? || linked_cost_share.nil? || !allowed_cost_share_ids.include?(linked_cost_share.id)
      cost_share_link.errors.add(:linked_cost_share, "must be selected from this plan")
    else
      cost_share_link.linked_cost_share = linked_cost_share
    end

    if cost_share_link.errors.any?
      return WizardStepResult.new(success: false, resource: cost_share_link, errors: cost_share_link.errors.full_messages)
    end

    if cost_share_link.save
      WizardStepResult.new(success: true, resource: cost_share_link)
    else
      WizardStepResult.new(success: false, resource: cost_share_link, errors: cost_share_link.errors.full_messages)
    end
  end

  def save_review(review_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before review" ]) unless plan.present?
    plan_version = plan_version_for(plan)
    return WizardStepResult.new(success: false, errors: [ "Plan version is missing" ]) unless plan_version.present?

    # Only act when finishing the wizard
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "complete"

    publish_now = ActiveModel::Type::Boolean.new.cast(review_params&.[](:publish_now))
    errors = nil

    ActiveRecord::Base.transaction do
      if publish_now
        plan_version.published = true
        plan_version.current = true
        unless close_previous_published_version(plan_version)
          errors = plan_version.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end

      unless plan_version.save
        errors = plan_version.errors.full_messages
        raise ActiveRecord::Rollback
      end
    end

    if errors.nil?
      WizardStepResult.new(success: true, resource: plan)
    else
      plan_version.errors.each do |error|
        plan.errors.add(error.attribute, error.message)
      end
      WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
    end
  end

  private

  def cost_share_ids_for_plan(plan_version)
    return [] unless plan_version

    module_ids = plan_version.plan_module_ids
    module_benefit_ids = ModuleBenefit.where(plan_module_id: module_ids).pluck(:id)
    benefit_limit_group_ids = BenefitLimitGroup.where(plan_module_id: module_ids).pluck(:id)

    [
      plan_version.cost_share_ids,
      CostShare.where(scope_type: "PlanModule", scope_id: module_ids).pluck(:id),
      CostShare.where(scope_type: "ModuleBenefit", scope_id: module_benefit_ids).pluck(:id),
      CostShare.where(scope_type: "BenefitLimitGroup", scope_id: benefit_limit_group_ids).pluck(:id)
    ].flatten.uniq
  end

  def plan_version_for(plan)
    progress.plan_version || plan&.current_plan_version
  end

  def close_previous_published_version(plan_version)
    return true if plan_version.effective_on.blank?

    previous_version =
      plan_version.plan.plan_versions
        .where(published: true, effective_through: nil)
        .where.not(id: plan_version.id)
        .where("effective_on <= ?", plan_version.effective_on)
        .order(effective_on: :desc)
        .first

    return true if previous_version.nil?

    if plan_version.effective_on <= previous_version.effective_on
      plan_version.errors.add(:effective_on, "must be after #{previous_version.effective_on}")
      return false
    end

    unless previous_version.update(
      effective_through: plan_version.effective_on - 1.day,
      current: false
    )
      previous_version.errors.full_messages.each do |message|
        plan_version.errors.add(:base, message)
      end
      return false
    end

    true
  end

  def explicit_plan_version_for(plan)
    return unless plan.is_a?(Plan)

    version_id = progress.metadata&.fetch("plan_version_id", nil)
    return if version_id.blank?

    plan.plan_versions.find_by(id: version_id)
  end
end
