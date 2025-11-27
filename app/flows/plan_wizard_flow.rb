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
    when "module_benefits"      then save_module_benefits(params[:benefits], params[:step_action])
    when "benefit_limit_groups" then save_benefit_limit_groups(params[:benefit_limit_groups], params[:step_action])
    when "cost_shares"   then save_cost_shares(params[:cost_shares], params[:step_action])
    when "cost_share_links" then save_cost_share_links(params[:cost_share_links], params[:step_action])
    when "review"        then save_review(params[:review], params[:step_action])
    else
      WizardStepResult.new(success: true)
    end
  end

  def save_plan_details(plan_params)
    raise ActionController::ParameterMissing, :plan if plan_params.nil?
    plan = progress.subject || Plan.new
    plan.assign_attributes(
      plan_params.permit(
        :insurer_id,
        :name,
        :min_age,
        :max_age,
        :children_only_allowed,
        :version_year,
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
    )

    ActiveRecord::Base.transaction do
      if plan.save
        progress.update!(subject: plan)
        WizardStepResult.new(success: true, resource: plan)
      else
        WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
      end
    end
  end

  def save_plan_residency(residency_params)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before setting residency eligibility" ]) unless plan.present?

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
      plan.plan_residency_eligibilities.where.not(country_code: country_codes).destroy_all
      country_codes.each do |code|
        plan.plan_residency_eligibilities.find_or_create_by!(country_code: code)
      end
    end

    plan.plan_residency_eligibilities.reload

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
        plan.plan_geographic_cover_areas.destroy_all
      else
        plan.plan_geographic_cover_areas.where.not(geographic_cover_area_id: existing_ids).destroy_all
        existing_ids.each do |area_id|
          plan.plan_geographic_cover_areas.find_or_create_by!(geographic_cover_area_id: area_id)
        end
      end
    end

    plan.plan_geographic_cover_areas.reload
    plan.geographic_cover_areas.reset

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

    # Only attempt to create a new module group when explicitly asked
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    params_for_group =
      case module_group_params
      when ActionController::Parameters then module_group_params
      when Hash then ActionController::Parameters.new(module_group_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_group.permit(:name, :description, :position)
    sanitized_values = permitted.to_h

    module_group = plan.module_groups.build(sanitized_values)
    module_group.position ||= plan.module_groups.maximum(:position).to_i + 1

    if sanitized_values["name"].to_s.strip.blank?
      module_group.validate
      module_group.errors.add(:name, "can't be blank") if module_group.errors[:name].blank?
      return WizardStepResult.new(success: false, resource: module_group, errors: module_group.errors.full_messages)
    end

    if module_group.save
      plan.module_groups.reload
      WizardStepResult.new(success: true, resource: module_group)
    else
      WizardStepResult.new(success: false, resource: module_group, errors: module_group.errors.full_messages)
    end
  end

  def save_plan_modules(module_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding plan modules" ]) unless plan.present?

    # Only create a new module when explicitly requested
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    params_for_module =
      case module_params
      when ActionController::Parameters then module_params
      when Hash then ActionController::Parameters.new(module_params)
      else
        ActionController::Parameters.new
      end

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
                                         :overall_limit_notes)
    sanitized_values = permitted.to_h
    sanitized_values["is_core"] = ActiveModel::Type::Boolean.new.cast(sanitized_values["is_core"])

    plan_module = plan.plan_modules.build(sanitized_values)

    # Guard against selecting a module group from another plan
    if plan_module.module_group_id.present? && !plan.module_groups.exists?(id: plan_module.module_group_id)
      plan_module.errors.add(:module_group, "must belong to this plan")
      return WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end

    if plan_module.save
      plan.plan_modules.reload
      WizardStepResult.new(success: true, resource: plan_module)
    else
      WizardStepResult.new(success: false, resource: plan_module, errors: plan_module.errors.full_messages)
    end
  end

  def save_module_benefits(benefit_params, step_action = nil)
    plan = progress.subject
    return WizardStepResult.new(success: false, errors: [ "Plan must be created before adding module benefits" ]) unless plan.present?

    # Only create a new module benefit when explicitly asked
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    params_for_benefit =
      case benefit_params
      when ActionController::Parameters then benefit_params
      when Hash then ActionController::Parameters.new(benefit_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_benefit.permit(:plan_module_id,
                                          :benefit_id,
                                          :coverage_category_id,
                                          :coverage_description,
                                          :limit_usd,
                                          :limit_gbp,
                                          :limit_eur,
                                          :limit_unit,
                                          :sub_limit_description,
                                          :interaction_type,
                                          :weighting)

    sanitized_values = permitted.to_h
    sanitized_values["weighting"] = sanitized_values["weighting"].presence || nil

    plan_module = plan.plan_modules.find_by(id: sanitized_values["plan_module_id"])

    unless plan_module
      module_benefit = ModuleBenefit.new
      module_benefit.errors.add(:plan_module, "must belong to this plan")
      return WizardStepResult.new(success: false, resource: module_benefit, errors: module_benefit.errors.full_messages)
    end

    module_benefit = ModuleBenefit.new(sanitized_values.merge(plan_module:))

    # default weighting to next available slot if not provided
    if module_benefit.weighting.nil?
      max_weighting = ModuleBenefit.where(plan_module_id: plan.plan_module_ids).maximum(:weighting)
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

    return WizardStepResult.new(success: true, resource: plan) unless step_action == "add"

    params_for_group =
      case group_params
      when ActionController::Parameters then group_params
      when Hash then ActionController::Parameters.new(group_params)
      else
        ActionController::Parameters.new
      end

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

    plan_module = plan.plan_modules.find_by(id: sanitized_values["plan_module_id"])
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
                                             :notes)

    sanitized = permitted.to_h
    # Only treat this submission as a create when meaningful fields are present.
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
        plan
      when "plan_module"
        plan.plan_modules.find_by(id: plan_module_id)
      when "module_benefit"
        ModuleBenefit.where(plan_module_id: plan.plan_module_ids).find_by(id: module_benefit_id)
      when "benefit_limit_group"
        BenefitLimitGroup.where(plan_module_id: plan.plan_module_ids).find_by(id: benefit_limit_group_id)
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

    params_for_cost_share_link =
      case cost_share_link_params
      when ActionController::Parameters then cost_share_link_params
      when Hash then ActionController::Parameters.new(cost_share_link_params)
      else
        ActionController::Parameters.new
      end

    permitted = params_for_cost_share_link.permit(:cost_share_id, :linked_cost_share_id, :relationship_type)
    sanitized = permitted.to_h

    user_filled_any = sanitized.values.any?(&:present?)
    creating = step_action.in?([ "add", "next" ]) || (step_action.blank? && user_filled_any)
    return WizardStepResult.new(success: true, resource: plan) unless creating && user_filled_any

    cost_share_link = CostShareLink.new(relationship_type: permitted[:relationship_type])
    allowed_cost_share_ids = cost_share_ids_for_plan(plan)

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

    # Only act when finishing the wizard
    return WizardStepResult.new(success: true, resource: plan) unless step_action == "complete"

    publish_now = ActiveModel::Type::Boolean.new.cast(review_params&.[](:publish_now))
    plan.published = true if publish_now

    if plan.save
      WizardStepResult.new(success: true, resource: plan)
    else
      WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages)
    end
  end

  private

  def cost_share_ids_for_plan(plan)
    module_ids = plan.plan_module_ids
    module_benefit_ids = ModuleBenefit.where(plan_module_id: module_ids).pluck(:id)

    [
      plan.cost_share_ids,
      CostShare.where(scope_type: "PlanModule", scope_id: module_ids).pluck(:id),
      CostShare.where(scope_type: "ModuleBenefit", scope_id: module_benefit_ids).pluck(:id)
    ].flatten.uniq
  end
end
