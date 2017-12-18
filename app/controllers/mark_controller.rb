class MarkController < ApplicationController

  #respond_to :json
  # GET /mark
  # GET /mark.json
  def index
    @marks = Mark.all
    render json: @marks
  end

  # POST /mark
  # POST /mark.json
  def new
    @mark = Mark.new(mark_params)

    if @mark.save
      render json: @mark, status: :created
    else
      render json: @mark.errors, status: :unprocessable_entity
    end
  end
  
  private
  def mark_params
    params.permit(:start_x,:start_y,:end_x,:end_y,:page_version_id)
  end
  
end
