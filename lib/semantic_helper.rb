require_relative 'semantic_clients/virtuoso-client'
require_relative 'semantic_clients/default-semantic-client'

class SemanticHelper

  @@semanticClient = nil

  #### Insert a new group of triplets ####
  def self.insert(data)
    semanticClient.insert(data)
  end

  #### Insert a new relation triplet ####
  def self.insert_relation(subject_id, predicate_id, object_id)
    semanticClient.insert_relation(subject_id, predicate_id, object_id)
  end
  
  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listSemanticContributions(data = {})
    semanticClient.listSemanticContributions(buildFilterIfRequested(data, ['propertyValue','propertyName','entityTypeLike']))
  end
  
  ## Lists semantic contributions matching entityId ##
  def self.listSemanticContributionsByEntity(data = {})
    semanticClient.listSemanticContributionsByEntity(data)
  end

  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listEntities(data = {})
    semanticClient.listEntities(data)
  end

  def self.describeEntity(id, useDefaultGraph = false)
    semanticClient.describeEntity(id, useDefaultGraph)
  end

  def self.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    semanticClient.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph)
  end

  def self.list_classes(ontology_id, parent = nil)
    semanticClient.list_classes(ontology_id, parent)
  end

  def self.list_properties(class_id, ontology_id = nil)
    semanticClient.list_properties(class_id, ontology_id)
  end

  def self.list_relations(class_id, ontology_id = nil)
    semanticClient.list_relations(class_id, ontology_id)
  end

  def self.upload_ontology(ontology)
    semanticClient.upload_ontology(ontology)
  end

  def self.search_loaded_components(searchText, semantic_component)
    semanticClient.search_loaded_components(searchText, semantic_component)
  end

  def self.semanticClient
    if (@@semanticClient == nil)
      @@semanticClient = createSemanticClient()
    end
    return @@semanticClient
  end

  def self.createSemanticClient
    case ENV['SEMANTIC_CONNECTOR']
      when 'virtuoso'
        return VirtuosoClient.new()
      else
        return DefaultSemanticClient.new()
    end
  end

  def self.createFilterFrom(query)
    if(query.gsub(/(([^\,\+]+:[^\,\+]+)([\,\+]))*([^\,\+]+:[^\,\+]+)/, '').length == 0)
      conditionSeparator=','
      incrementalSeparator='+'
      fieldValueSeparator=':'
      return query.split(conditionSeparator).map { |condition| condition.split(incrementalSeparator).map { |keyValueString| {keyValueString.split(fieldValueSeparator)[0] => keyValueString.split(fieldValueSeparator)[1]} } }
    end
    return []
  end

  def self.buildFilterIfRequested(filter, defaultKeys = [])
    filter['searchQueryConditions'] = []
    filter['searchQuery'] = filter['searchQuery']&.strip
    if(filter['searchQuery'])
      searchQueryConditions = createFilterFrom(filter['searchQuery'])
      if(searchQueryConditions.length > 0)
        filter['searchQueryConditions'] = searchQueryConditions
      else
        for defaultKey in defaultKeys do
          filter[defaultKey] = filter['searchQuery']
        end
      end
    end
    return filter
  end
end
