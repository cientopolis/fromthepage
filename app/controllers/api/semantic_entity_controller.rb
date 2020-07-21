class Api::SemanticEntityController < Api::ApiController

  before_action :set_search_filter, only: [:list]

  def public_actions
    return [:list, :show, :add_relation]
  end

  def list
    response_serialized_object SemanticHelper.listEntities(@filter)
  end

  def show
    if (params[:is_contribution] && params[:is_contribution] == 'true')
      response_serialized_object SemanticHelper.describeSemanticContributionEntity(params[:entity_id], params[:use_default_schema])
    else
      response_serialized_object SemanticHelper.describeEntity(params[:entity_id], params[:use_default_schema])
    end
  end

  def add_relation
    params.permit(:subject_id, :predicate_id, :object_id)
    if params[:subject_id].present? && params[:predicate_id].present? && params[:object_id].present?
      if (SemanticHelper.insert_relation(params[:subject_id], params[:predicate_id], params[:object_id]) != nil)
        render_serialized ResponseWS.simple_ok('api.default.ok')
      else
        render_serialized ResponseWS.simple_error('api.default.error')
      end
    else
      render_serialized ResponseWS.simple_error('api.default.error')
    end
  end

  private
    def set_search_filter
      params.permit(:filter)
      @filter = params[:filter] || {}
    end

end