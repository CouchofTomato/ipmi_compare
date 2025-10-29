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
    end
  end
end
