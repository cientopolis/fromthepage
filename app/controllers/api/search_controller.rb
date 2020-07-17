class Api::SearchController < Api::ApiController

  include ApplicationHelper

  before_action :set_search_filter, only: [:list_semantic_references, :list_semantic_references_by_properties]

  def public_actions
    return [:list_semantic_references, :list_semantic_references_by_properties]
  end

  def list_semantic_references
    entities = SemanticHelper.listSemanticContributionsByEntity(@filter)&.bindings || []
    entityIDs = entities.map{ |entity| entity.idNote&.value&.split('/').last }
    info = SemanticContribution.select(
        'collections.id AS `collectionId`','collections.title AS `collectionTitle`',
        'works.id AS `workId`','works.title AS `workTitle`',
        'pages.id AS `pageId`','pages.title AS `pageTitle`',
        'pages.base_image', 'count(*) AS `referencesAmount`'
    ).joins(mark: { page: { work: :collection } }).where('contributions.slug in (?)', entityIDs).group('pages.id')
    info = getSemanticReferencesData(info)
    response_data = { referenced_slugs: entityIDs, references: info }
    response_serialized_object response_data
  end

  def list_semantic_references_by_properties
    response_serialized_object SemanticHelper.listSemanticContributions(@filter)
  end

  private
    def getSemanticReferencesData(semanticReferencesData)
      semanticReferences = [] 
      for semanticReference in semanticReferencesData do
        semanticReferenceHash = semanticReference.attributes
        semanticReferenceHash[:thumbnail] = semanticReference.base_image.split('.').join('_thumb.')
        semanticReferenceHash[:thumbnail] = file_to_url(semanticReferenceHash[:thumbnail])
        semanticReferenceHash[:base_image] = file_to_url(semanticReference.base_image)
        semanticReferences.push(semanticReferenceHash)
      end
      return semanticReferences
    end

  private
    def set_search_filter
      params.permit(:filter)
      @filter = params[:filter] || {}
    end
end