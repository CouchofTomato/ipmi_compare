class GeographicCoverAreasController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_geographic_cover_area, only: %i[show edit update destroy]

  def index
    @geographic_cover_areas = GeographicCoverArea.order(:name)
  end

  def show
  end

  def new
    @geographic_cover_area = GeographicCoverArea.new
  end

  def edit
  end

  def create
    @geographic_cover_area = GeographicCoverArea.new(geographic_cover_area_params)

    if @geographic_cover_area.save
      redirect_to @geographic_cover_area, notice: "Geographic cover area was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @geographic_cover_area.update(geographic_cover_area_params)
      redirect_to @geographic_cover_area, notice: "Geographic cover area was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @geographic_cover_area.destroy
    redirect_to geographic_cover_areas_path, notice: "Geographic cover area was successfully deleted."
  end

  private

    def set_geographic_cover_area
      @geographic_cover_area = GeographicCoverArea.find(params[:id])
    end

    def geographic_cover_area_params
      params.require(:geographic_cover_area).permit(:name, :code)
    end
end
