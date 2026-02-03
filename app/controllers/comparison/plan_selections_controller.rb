class Comparison::PlanSelectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wizard_progress
  before_action :set_presenter

  def search
    @plans = @presenter.search(params[:q])

    render turbo_stream: turbo_stream.update(
      "plan_search_results",
      partial: "comparison/plan_selections/search",
      locals: { plans: @plans, wizard_progress: @wizard_progress }
    )
  end

  def add
    plan = Plan.includes(current_plan_version: { module_groups: :plan_modules }).find_by(id: params[:plan_id])

    unless plan
      return redirect_back fallback_location: wizard_progress_path(@wizard_progress),
                           alert: "Plan not found. Please search again."
    end

    module_selections = filtered_module_selections(plan)
    state = @wizard_progress.state.deep_dup
    selections = normalized_plan_selections(state)

    if selections.any? { |sel| same_selection?(sel, plan.id, module_selections) }
      return respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "This plan with the same modules is already added."
          render turbo_stream: turbo_stream.replace(
            "plan_selection",
            partial: "wizard_progresses/steps/plan_comparison/plan_selection",
            locals: { progress: @wizard_progress, presenter: @presenter }
          )
        end

        format.html do
          redirect_back fallback_location: wizard_progress_path(@wizard_progress),
                        alert: "This plan with the same modules is already added."
        end
      end
    end

    selections << {
      "id" => SecureRandom.uuid,
      "plan_id" => plan.id,
      "module_groups" => module_selections
    }

    state["plan_selections"] = selections

    @wizard_progress.update!(state:, last_actor: current_user)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "plan_selection",
          partial: "wizard_progresses/steps/plan_comparison/plan_selection",
          locals: { progress: @wizard_progress, presenter: @presenter }
        )
      end

      format.html { redirect_to wizard_progress_path(@wizard_progress), notice: "Plan selection saved." }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: wizard_progress_path(@wizard_progress),
                  alert: "Could not save selection: #{e.record.errors.full_messages.to_sentence}"
  end

  def remove
    state = @wizard_progress.state.deep_dup
    selections = normalized_plan_selections(state)
    selection_id = params[:selection_id].presence
    plan_id = params[:plan_id].presence

    selections.reject! do |selection|
      selection["id"].to_s == selection_id ||
        (selection_id.blank? && plan_id.present? && selection["plan_id"].to_s == plan_id)
    end

    state["plan_selections"] = selections

    @wizard_progress.update!(state:, last_actor: current_user)

    respond_to do |format|
      format.turbo_stream do
        if @wizard_progress.current_step == "comparison" || request.headers["Turbo-Frame"] == "wizard_step"
          render turbo_stream: turbo_stream.replace(
            "wizard_step",
            partial: "wizard_progresses/steps/plan_comparison/comparison",
            locals: { progress: @wizard_progress, presenter: WizardProgresses::Comparison::ComparisonPresenter.new(@wizard_progress) }
          )
        else
          render turbo_stream: turbo_stream.replace(
            "plan_selection",
            partial: "wizard_progresses/steps/plan_comparison/plan_selection",
            locals: { progress: @wizard_progress, presenter: @presenter }
          )
        end
      end

      format.html { redirect_to wizard_progress_path(@wizard_progress), notice: "Plan selection removed." }
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: wizard_progress_path(@wizard_progress),
                  alert: "Could not remove selection: #{e.record.errors.full_messages.to_sentence}"
  end

  def export
    @comparison_data = ComparisonBuilder.new(@wizard_progress).build
    @comparison_name = @wizard_progress.comparison_name_from_state || "Plan comparison"
    @exclude_uncovered = ActiveModel::Type::Boolean.new.cast(params[:exclude_uncovered])

    respond_to do |format|
      format.xlsx do
        safe_name = @comparison_name.parameterize.presence || "plan-comparison"
        date_stamp = Time.zone.today.iso8601
        response.headers["Content-Disposition"] = %(attachment; filename="#{safe_name}-#{date_stamp}.xlsx")
      end
      format.html do
        redirect_to wizard_progress_path(@wizard_progress),
                    alert: "Export is available as an Excel download."
      end
    end
  end

  private

  def set_wizard_progress
    @wizard_progress = current_user.wizard_progresses.find(params[:wizard_progress_id])
  end

  def set_presenter
    @presenter = WizardProgresses::Comparison::PlanSelectionPresenter.new(@wizard_progress)
  end

  def filtered_module_selections(plan)
    raw_params =
      if params[:module_groups].respond_to?(:to_unsafe_h)
        params[:module_groups].to_unsafe_h
      else
        params.fetch(:module_groups, {})
      end

    raw_params.each_with_object({}) do |(group_id, module_id), selections|
      group = plan.module_groups.find { |g| g.id.to_s == group_id.to_s }
      next unless group

      module_id_int = module_id.to_i
      next unless group.plan_module_ids.include?(module_id_int)

      selections[group.id.to_s] = module_id_int
    end
  end

  def normalized_plan_selections(state)
    raw = state["plan_selections"]
    list =
      case raw
      when Hash then raw.values
      when Array then raw
      else []
      end

    list.map do |selection|
      selection = selection.deep_dup
      selection["id"] ||= SecureRandom.uuid
      selection
    end
  end

  def normalize_modules(modules_hash)
    return {} if modules_hash.blank?
    modules_hash.to_h.stringify_keys
  end

  def same_selection?(selection, plan_id, module_selections)
    selection["plan_id"].to_i == plan_id.to_i &&
      normalize_modules(selection["module_groups"]) == normalize_modules(module_selections)
  end
end
