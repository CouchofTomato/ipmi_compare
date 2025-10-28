class PlansController < ApplicationController
  before_action :set_plan, only: %i[show]

  def index
    @plans = Plan.includes(:insurer).order(:name)
  end

  def show
  end

  def new
    @plan = Plan.new(
      children_only_allowed: false,
      published: false,
      overall_limit_unlimited: true,
      version_year: Time.current.year,
      next_review_due: 1.year.from_now.to_date
    )
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
        :overall_limit_usd,
        :overall_limit_gbp,
        :overall_limit_eur,
        :overall_limit_unit,
        :overall_limit_notes,
        :overall_limit_unlimited
      )
    end
end
