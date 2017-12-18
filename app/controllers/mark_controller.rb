class MarkController < ApplicationController
  
  before_action :set_mark, only: [:delete]

  #respond_to :json
  # GET /mark
  # GET /mark.json
  def index
    @marks = MarkQuery.new.result(mark_params).all
    render json: @marks
  end

  # POST /mark/new
  # POST /mark/new.json
  def new
    @mark = Mark.new(mark_params)

    if @mark.save
      render json: @mark, status: :created
    else
      render json: @mark.errors, status: :unprocessable_entity
    end
  end
  
  # DELETE /mark/delete
  # DELETE /mark/delete.json
  def delete
    @mark.destroy!
    
    render json: {deleted: "Mark has been deleted successfully"}
    
  end
  
  private
    
    def mark_params
      params.permit(:start_x,:start_y,:end_x,:end_y,:page_version_id)
    end
    
    def set_mark
      @mark = Mark.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @mark
    end
  
  
end
