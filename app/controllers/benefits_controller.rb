class BenefitsController < ApplicationController
  before_action :set_benefit, only: %i[show edit update destroy]

  def index
    @benefits = Benefit.order(:name)
  end

  def show
  end

  def new
    @benefit = Benefit.new
  end

  def edit
  end

  def create
    @benefit = Benefit.new(benefit_params)

    if @benefit.save
      redirect_to @benefit, notice: "Benefit was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @benefit.update(benefit_params)
      redirect_to @benefit, notice: "Benefit was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @benefit.destroy
    redirect_to benefits_path, notice: "Benefit was successfully deleted."
  end

  private

    def set_benefit
      @benefit = Benefit.find(params[:id])
    end

    def benefit_params
      params.require(:benefit).permit(:name, :description, :coverage_category_id)
    end
end
