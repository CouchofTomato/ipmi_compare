class WizardProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_for_plan_wizard_index, only: %i[index]
  before_action :set_progress, only: %i[show update destroy]
  before_action :require_admin_for_plan_wizard, only: %i[create show update destroy]
  before_action :redirect_if_complete, only: %i[show update]
  before_action :presenter_for_current_step, only: %i[show update]

  def index
    @status = params[:status].presence_in(%w[in_progress complete]) || "in_progress"
    @wizard_type = params[:wizard_type].presence || "plan_comparison"
    @wizard_progresses = current_user.wizard_progresses.where(status: @status, wizard_type: @wizard_type).order(updated_at: :desc)
  end

  def create
    wizard_type = params.fetch(:wizard_type, "plan_creation")
    plan = Plan.find_by(id: params[:plan_id]) if params[:plan_id].present?

    if params[:plan_id].present? && plan.nil?
      return redirect_back fallback_location: plans_path,
                           alert: "Plan not found. Please try again from the plan list."
    end

    progress =
      if plan.present?
        current_user.wizard_progresses.find_or_initialize_by(wizard_type:, subject: plan)
      else
        current_user.wizard_progresses.new(wizard_type:)
      end

    was_in_progress = progress.in_progress?

    progress.user ||= current_user
    progress.last_actor = current_user
    progress.subject ||= plan
    progress.started_at = Time.current if progress.started_at.blank? || !progress.in_progress?

    if !progress.in_progress? || progress.current_step.blank?
      progress.status = :in_progress
      progress.current_step = progress.steps.first
    end

    progress.step_order = progress.current_step_index

    assign_plan_version_metadata(progress, plan, was_in_progress, params[:new_version].present?)

    if progress.save
      redirect_to wizard_progress_path(progress)
    else
      redirect_back fallback_location: plan ? plan_path(plan) : root_path,
                    alert: "Could not start the wizard: #{progress.errors.full_messages.to_sentence}"
    end
  end

  def show
    render "wizard_progresses/show", locals: { progress: @progress, presenter: @presenter }
  end

  def update
    if params[:step_action] == "restore"
      return restore_comparison
    end

    if params[:wizard_progress].is_a?(Hash) && params[:wizard_progress].key?(:name)
      @progress.update!(name: params[:wizard_progress][:name])
    end

    result = @progress.flow.handle_step(params)
    @resource = result.resource if params[:step_action] == "edit" && result.resource.present?

    if result.success?
      case params[:step_action]
      when "next"
        next_step = @progress.next_step
        @progress.update!(current_step: next_step)
        update_comparison_name_if_ready(next_step)
      when "previous" then @progress.update!(current_step: @progress.previous_step)
      when "complete" then @progress.update!(status: :complete, completed_at: Time.current)
      end
    else
      @resource = result.resource
      result.errors.each { |e| @progress.errors.add(:base, e) }
    end

    return if redirect_to_plan_if_complete

    render_current_step
  end

  def destroy
    @progress.destroy

    redirect_to wizard_progresses_path, notice: "Wizard session deleted."
  end

  private

  def presenter_for_current_step
    @presenter = @progress.flow.presenter_for(@progress.current_step)
  end

  def assign_plan_version_metadata(progress, plan, was_in_progress, create_new_version)
    return unless plan.present?
    return unless progress.wizard_type == "plan_creation"
    unless create_new_version
      progress.metadata = progress.metadata.except("plan_version_id") if progress.metadata&.key?("plan_version_id")
      return
    end
    return if was_in_progress && progress.metadata["plan_version_id"].present?

    source_version = plan.current_plan_version || plan.plan_versions.current.first || plan.plan_versions.first
    return unless source_version

    draft_version = PlanVersionDuplicator.call(source_version)
    progress.metadata ||= {}
    progress.metadata = progress.metadata.merge("plan_version_id" => draft_version.id)
  end

  def update_comparison_name_if_ready(next_step)
    return unless @progress.wizard_type == "plan_comparison"
    return unless next_step == "comparison"
    return unless @progress.name.blank?

    generated_name = @progress.comparison_name_from_state
    return if generated_name.blank?

    @progress.update!(name: generated_name)
  end

  def render_current_step
    presenter = @progress.flow.presenter_for(@progress.current_step) || @presenter

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "wizard_step",
          partial: "wizard_progresses/steps/#{@progress.wizard_type}/#{@progress.current_step}",
          locals: { progress: @progress, resource: @resource, presenter: presenter }
        )
      end

      format.html { redirect_to wizard_progress_path(@progress, resource: @resource, presenter: presenter) }
    end
  end

  def set_progress
    @progress = current_user.wizard_progresses.find(params[:id])
  end

  def require_admin_for_plan_wizard
    wizard_type = @progress&.wizard_type || params[:wizard_type].presence || "plan_creation"
    return if wizard_type != "plan_creation"

    require_admin!
  end

  def require_admin_for_plan_wizard_index
    return unless params[:wizard_type] == "plan_creation"

    require_admin!
  end

  def restore_comparison
    unless @progress.wizard_type == "plan_comparison"
      return redirect_back fallback_location: wizard_progresses_path, alert: "Only comparisons can be restored."
    end

    unless @progress.complete?
      return redirect_back fallback_location: wizard_progresses_path, alert: "Only archived comparisons can be restored."
    end

    @progress.update!(status: :in_progress, completed_at: nil)

    redirect_to wizard_progresses_path(status: "in_progress", wizard_type: "plan_comparison"),
                notice: "Comparison restored."
  end

  def redirect_if_complete
    return if params[:step_action] == "restore"

    redirect_to_plan_if_complete
  end

  def redirect_to_plan_if_complete
    return false unless @progress.complete?

    if @progress.subject.is_a?(Plan)
      respond_to do |format|
        format.turbo_stream do
          redirect_to plan_path(@progress.subject),
                      notice: "Plan published and wizard completed",
                      status: :see_other
        end
        format.html do
          redirect_to plan_path(@progress.subject),
                      notice: "Plan published and wizard completed",
                      status: :see_other
        end
      end

      return true
    end

    if @progress.wizard_type == "plan_comparison" && !request.get?
      respond_to do |format|
        format.turbo_stream do
          redirect_to wizard_progresses_path(status: "complete"),
                      notice: "Comparison archived",
                      status: :see_other
        end
        format.html do
          redirect_to wizard_progresses_path(status: "complete"),
                      notice: "Comparison archived",
                      status: :see_other
        end
      end

      return true
    end

    false
  end
end
