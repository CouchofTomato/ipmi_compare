class PlansController < ApplicationController
  before_action :set_plan, only: %i[show]

  def index
    @plans = Plan.includes(:insurer).order(:name)
  end

  def show
  end

  def new
    @plan = Plan.new
  end

  def create
    @plan = Plan.new(plan_params)

    if @plan.save
      redirect_to @plan, notice: "Plan was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def set_plan
      @plan = Plan.find(params[:id])
    end

    def plan_params
      params.require(:plan).permit(
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
      )
    end
end
