class WizardProgressesController < ApplicationController
  before_action :set_progress

  def show
    render "wizard_progresses/show", locals: { progress: @progress }
  end

  def update
    # Delegates logic to flow
    @progress.flow.handle_step(params)

    # Handle navigation
    case params[:step_action]
    when "next"
      @progress.update!(current_step: @progress.next_step)
    when "previous"
      @progress.update!(current_step: @progress.previous_step)
    when "complete"
      @progress.update!(status: :completed)
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "wizard_step",
          partial: "wizard_progresses/steps/#{@progress.wizard_type}/#{@progress.current_step}",
          locals: { progress: @progress }
        )
      end

      format.html { redirect_to wizard_progress_path(@progress) }
    end
  end

  private

  def set_progress
    @progress = WizardProgress.find(params[:id])
  end
end
