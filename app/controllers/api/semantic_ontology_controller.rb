require 'rdf/rdfa'

class Api::SemanticOntologyController < Api::ApiController

  before_action :set_type, only: [:get_schema_type]

  def public_actions
    return [:list_classes]
  end

  def list_classes
    response_serialized_object SemanticHelper.list_classes(params[:parent])
  end

end