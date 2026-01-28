class InsurersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_insurer, only: %i[show edit update destroy]

  def index
    @insurers = Insurer.order(:name)
  end

  def show
  end

  def new
    @insurer = Insurer.new
  end

  def edit
  end

  def create
    @insurer = Insurer.new(insurer_params)

    if @insurer.save
      redirect_to @insurer, notice: "Insurer was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @insurer.update(insurer_params)
      redirect_to @insurer, notice: "Insurer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @insurer.destroy
    redirect_to insurers_url, notice: "Insurer was successfully destroyed."
  end

  private

    def set_insurer
      @insurer = Insurer.find(params[:id])
    end

    def insurer_params
      params.require(:insurer).permit(:name, :jurisdiction, :logo)
    end
end
