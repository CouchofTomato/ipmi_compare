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
  end
end
