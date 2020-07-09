require 'rdf/rdfa'

class Api::SemanticOntologyController < Api::ApiController

  before_action :set_type, only: [:get_schema_type]

  def public_actions
    return [:list_classes, :list_properties, :list_relations]
  end

  def list_classes
    response_serialized_object SemanticHelper.list_classes(params[:ontology_id], params[:parent])
  end

  def list_properties
    response_serialized_object SemanticHelper.list_properties(params[:class], params[:ontology_id])
  end  
  
  def list_relations
    response_serialized_object SemanticHelper.list_relations(params[:class], params[:ontology_id])
  end

end