class WizardProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_progress, only: %i[show update]

  def create
    wizard_type = params.fetch(:wizard_type, "plan_creation")

    progress = WizardProgress.new(
      wizard_type:,
      user: current_user,
      started_at: Time.current
    )

    progress.current_step = progress.steps.first

    if progress.save
      redirect_to wizard_progress_path(progress)
    else
      redirect_back fallback_location: root_path,
                    alert: "Could not start the wizard: #{progress.errors.full_messages.to_sentence}"
    end
  end

  def show
    render "wizard_progresses/show", locals: { progress: @progress }
  end

  def update
    result = @progress.flow.handle_step(params)

    if result.success?
    case params[:step_action]
    when "next"     then @progress.update!(current_step: @progress.next_step)
    when "previous" then @progress.update!(current_step: @progress.previous_step)
    when "complete" then @progress.update!(status: :completed)
    end
    else
    @resource = result.resource
    result.errors.each { |e| @progress.errors.add(:base, e) }
    end

    render_current_step
  end

  private

  def render_current_step
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "wizard_step",
          partial: "wizard_progresses/steps/#{@progress.wizard_type}/#{@progress.current_step}",
          locals: { progress: @progress, resource: @resource }
        )
      end

      format.html { redirect_to wizard_progress_path(@progress) }
    end
  end

  def set_progress
    @progress = WizardProgress.find(params[:id])
  end
end
