class CoverageCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_coverage_category, only: %i[show edit update destroy]

  def index
    @coverage_categories = CoverageCategory.order(:position, :name)
  end

  def show
  end

  def new
    @coverage_category = CoverageCategory.new
  end

  def edit
  end

  def create
    @coverage_category = CoverageCategory.new(coverage_category_params)

    if @coverage_category.save
      redirect_to @coverage_category, notice: "Coverage category was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coverage_category.update(coverage_category_params)
      redirect_to @coverage_category, notice: "Coverage category was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coverage_category.destroy
    redirect_to coverage_categories_path, notice: "Coverage category was successfully deleted."
  end

  private

    def set_coverage_category
      @coverage_category = CoverageCategory.find(params[:id])
    end

    def coverage_category_params
      params.require(:coverage_category).permit(:name, :position)
    end
end
