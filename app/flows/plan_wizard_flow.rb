class PlanWizardFlow
  attr_reader :progress

  def initialize(progress)
    @progress = progress
  end

  def steps
    %w[ plan_details plan_residency geographic_cover_areas plan_modules module_benefits cost_shares review]
  end

  def handle_step(params)
    case progress.current_step
    when "plan_details" then save_plan_details(params[:plan])
    when "plan_residency" then save_plan_residency(params[:residency])
    when "geographic_cover_areas" then save_geographic_cover_areas(params[:areas])
    when "plan_modules"       then save_plan_modules(params[:modules])
    when "module_benefits"      then save_module_benefits(params[:benefits])
    when "cost_shares"   then save_cost_shares(params[:cost_shares])
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
    return WizardStepResult.new(success: false, errors: ["Plan must be created before setting residency eligibility"]) unless plan.present?

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
    WizardStepResult.new(success: false, resource: plan, errors: plan.errors.full_messages.presence || ["Could not update residency eligibility"])
  end
end
