class Api::SemanticEntityController < Api::ApiController

  before_action :set_search_filter, only: [:list]

  def public_actions
    return [:list, :show]
  end

  def list
    response_serialized_object SemanticHelper.listEntities(@filter)
  end

  def show
    if (params[:is_contribution] && params[:is_contribution] == 'true')
      response_serialized_object SemanticHelper.describeSemanticContributionEntity(params[:entity_id], params[:use_default_schema])
    else
      lala = SemanticHelper.describeEntity(params[:entity_id], params[:use_default_schema])
      puts lala.inspect
      response_serialized_object lala
    end
  end

  private
    def set_search_filter
      params.permit(:filter)
      @filter = params[:filter] || {}
    end

end