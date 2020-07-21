require_relative '../http-client/http-client'
require_relative '../schema_helper'
require "base64"
require 'json/ld'
require 'rdf/turtle'
require 'sparql/client'

class VirtuosoClient

  def initialize()
    @host = ENV['VIRTUOSO_HOST']
    @collection = ENV['VIRTUOSO_COLLECTION']
    @graph = ENV['VIRTUOSO_GRAPH']
    @user = ENV['VIRTUOSO_USER']
    @password = ENV['VIRTUOSO_PASSWORD']
    @isql_path = ENV['VIRTUOSO_ISQL_PATH'] | "#{Dir.pwd}/bin/isql"
  end

  def insert(jsonld_string)
    # "Authorization": "Basic " + Base64.strict_encode64(@user + ":" + @password),
      headers = {
          "Content-Type": "application/sparql-query"
      }
      httpClient = HttpClient.new(@host, headers, 'raw')
      rdf_string = jsonldToRdf(jsonld_string)
      query = "INSERT IN GRAPH <#{ @graph }> { #{rdf_string} }"
      do_query(query)
  end

  def insert_relation(subject_id, predicate_id, object_id)
    # "Authorization": "Basic " + Base64.strict_encode64(@user + ":" + @password),
    if (subject_id && predicate_id && object_id)
      headers = {
          "Content-Type": "application/sparql-query"
      }
      httpClient = HttpClient.new(@host, headers, 'raw')
      query = "
      #{ getPrefixes() }
      
      INSERT IN GRAPH <#{ @graph }> { 
        #{formatId(subject_id)} #{formatId(predicate_id)} #{formatId(object_id)} .
      }"
      return do_query(query)
    end
    return nil
  end

  def listSemanticContributions(filter = {})
    begin
      matchedEntityTypes = getEntityTypes(filter)
      sanitizedFilter = filter
      # entityType = (sanitizedFilter['entityType'] != nil) ? "FILTER (?entityType = #{ formatId(filter['entityType']) }) ." : ''
      entityType = (matchedEntityTypes != nil) ? "FILTER (?entityType IN (#{ matchedEntityTypes.join(',') }) && ?entityType != schema:NoteDigitalDocument) " : "FILTER (?entityType != schema:NoteDigitalDocument) "
      includeMatchedProperties = filter['includeMatchedProperties']
      matchAllConditions = filter['matchAllConditions'] == true
      conditions = [
        {'propertyValue': "regex(?propertyValue, '#conditionValue', 'i')"},
        {'propertyName': "regex(?entityMatchingProperty, '#conditionValue', 'i')"},
        {'entityTypeLike': "regex(?entityType, '#conditionValue', 'i')"}
      ]
      statement = "
          #{ getPrefixes() }

          SELECT DISTINCT ?idNote ?entityType ?idMainEntity #{ includeMatchedProperties ? "(group_concat(?entityMatchingProperty;separator=',') as ?entityMatchingProperties)": '' }
          WHERE {
            ?idNote rdf:type schema:NoteDigitalDocument .
            ?idNote schema:mainEntity ?idMainEntity .
            ?idMainEntity rdf:type ?entityType .
            ?idMainEntity ?entityMatchingProperty ?propertyValue .
            #{ entityType }
            #{constructQueryFilters(filter, conditions)}
            #{constructFilters(filter, conditions, matchAllConditions)}
          }
          group by ?idNote ?entityType ?idMainEntity
      "
      return execute_sparql(statement)
    rescue => exception
      puts exception.inspect
      return []
    end
  end

  def constructFilters(receivedFilters, conditions, andConditions = false)
    operator = andConditions ? '&&' : '||'
    conditions = conditions.select { |condition| receivedFilters[condition.keys[0]] != nil }
    preparedConditions = conditions.map { |condition| {condition.keys[0] => condition.values[0] = condition.values[0].gsub(/#conditionValue/, receivedFilters[condition.keys[0]])} }
    filter = preparedConditions.reduce("") { |filter, condition| filter = addFilterCondition(filter, condition, operator) }
    closeFilterStatement(filter)
  end

  def constructQueryFilters(receivedFilters, conditions)
    partialFilters = []
    for searchQueryCondition in receivedFilters['searchQueryConditions'] do
      partialFilter = ""
      for basicCondition in searchQueryCondition do
        baseCondition = conditions.find{ |condition| condition.keys[0].to_s == basicCondition.keys[0].strip }
        if(baseCondition)
          conditionValue = baseCondition.values[0].gsub(/#conditionValue/, basicCondition[baseCondition.keys[0]])
          preparedCondition = {baseCondition.values[0] => conditionValue}
          partialFilter = addPartialFilterCondition(partialFilter, preparedCondition, '&&')
        end
      end
      if(partialFilter != "")
        partialFilters.push(closePartialFilterStatement(partialFilter))
      end
    end
    partialFilters.length > 0 ? "FILTER(#{partialFilters.join(" || ")}) ." : ""
  end

  def addPartialFilterCondition(partialFilter, condition, operator)
    partialFilter == '' ? condition.values[0] : "#{partialFilter} #{operator} #{condition.values[0]}" 
  end

  def closePartialFilterStatement(partialFilter)
    partialFilter == "" ? "" : "(#{partialFilter})"
  end

  def addFilterCondition(filter, condition, operator)
    filter == '' ? "FILTER(#{condition.values[0]}" : "#{filter} #{operator} #{condition.values[0]}" 
  end

  def closeFilterStatement(filter)
    filter == "" ? "" : filter + ") ."
  end

  def listSemanticContributionsByEntity(filter = {})
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    sanitizedFilter = sanitizeFilter(filter)
    propertyValue = (sanitizedFilter['entityId'] != nil) ? "FILTER regex(?propertyValue, '#{ filter['entityId'] }', 'i') " : ''
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?idNote 
        WHERE {
            ?idNote rdf:type schema:NoteDigitalDocument .
            ?idNote schema:mainEntity #{ getTranscriptorReference(filter['entityId']) } .
        }
    "
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def listEntities(filter)
    matchedEntityTypes = getEntityTypes(filter)
    sanitizedFilter = sanitizeFilter(filter)
    # defaultTypeFilter = "FILTER (?entityDefaultType IN (#{ getEntityTypes({"entityType" => 'schema:Thing', "hierarchical" => true}).join(',') })) "
    entityType = (matchedEntityTypes != nil) ? "FILTER (?entityType IN (#{ matchedEntityTypes.join(',') }) && ?entityType != schema:NoteDigitalDocument) " : "FILTER (?entityType != schema:NoteDigitalDocument) "
    propertyValue = (sanitizedFilter['labelValue'] != nil) ? "FILTER regex(?entityLabel, #{ sanitizedFilter['labelValue'] }, 'i') " : ''
    limit = (sanitizedFilter['limit']  != nil) ? "LIMIT #{ sanitizedFilter['limit'] }" : ''
    query = "
        #{ getPrefixes() }

        SELECT DISTINCT ?entityId, ?entityType, ?entityLabel
        WHERE {
            ?entityId rdf:type ?entityType #{ entityType }.
            ?entityId rdfs:label ?entityLabel #{ propertyValue }.
        }
        #{limit}
    "
    # ?entityId rdf:type ?entityDefaultType #{ defaultTypeFilter }.
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def describeEntity(entityId, useDefaultGraph = false)
    entityIdQuery = useDefaultGraph ? "#{@graph}/#{entityId}" : entityId
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    query = "
      #{ getPrefixes() }

      DESCRIBE <#{ entityIdQuery }> ?p ?q
      WHERE {
        <#{ entityIdQuery }> ?p ?q
      }
    "
    response = do_query(query)
    (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, entityId), entityId) : nil
  end

  def describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    idSemanticContributionQuery = useDefaultGraph ? "#{@graph}/#{idSemanticContribution}" : idSemanticContribution
    # sanitize with ActiveRecord::Base::sanitize_sql(string)
    query = "
        #{ getPrefixes() }

        DESCRIBE ?mainEntityId ?p ?q
        WHERE {
          <#{idSemanticContributionQuery}> <http://schema.org/mainEntity> ?mainEntityId .
          ?mainEntityId ?p ?q .
        }
    "
    response = do_query(query)
    semanticContribution = (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, idSemanticContribution), idSemanticContribution) : nil
    entityId = semanticContribution ? semanticContribution['schema:mainEntity']['@id'] : nil
    if entityId
      entityId = entityId.split(':').last
      return (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, entityId), entityId) : nil
    end
    return nil
    # (entity = response["data"].body) ? rdfToJsonld(entity, "transcriptor:#{idSemanticContribution}", true) : nil
  end

  def list_classes(ontology_id, parent = nil, include_parent = false)
    begin
      # ontology = Ontology.find_by(ontology_id ? { :id => ontology_id } : getOntologyFindCondition(parent))
      ontology = getOntology(ontology_id, parent)
      results = []
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      parentInclusionFilter = include_parent ? '*' : ''
      parentFilter = parent ? "?classId rdfs:subClassOf#{parentInclusionFilter} #{formatId(parent)} ." : "FILTER NOT EXISTS { ?classId rdfs:subClassOf ?parentClass . }"
      statement = "
      select ?label ?comment ?classId
      where {
        ?classId rdfs:label ?label.
        ?classId rdfs:comment ?comment.
        ?classId rdf:type #{ontology.class_type}.
        FILTER NOT EXISTS {
          ?classId rdf:type #{ontology.literal_type}
        }.
        #{parentFilter}
      }"
      puts statement
      query = sparql.query(statement)
      query&.each_solution do |solution|
        results.push({ id: solution[:classId].value, label: solution[:label].value, comment: solution[:comment].value})
      end
      return results
    rescue => exception
      puts exception.inspect
      return []
    end

  end

  def list_properties(class_id, ontology_id = nil)
    begin
      ontology = Ontology.find_by(getOntologyFindCondition(class_id, ontology_id))
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      literal_properties_filter = ontology.literal_filter
      results = []
      query = sparql.query("
      select ?property ?label ?comment (group_concat(?type;separator=',') as ?types)
      where {
          #{formatId(class_id)} rdfs:subClassOf* ?class .
          ?property #{ontology.domainkey} ?class .
          ?property rdfs:label ?label .
          ?property rdfs:comment ?comment .
          ?property #{ontology.rangekey} ?type .
          #{literal_properties_filter}
      }
      group by ?property ?label ?comment")
      query&.each_solution do |solution|
        results.push({ property: solution[:property].value, types: solution[:types].value.split(','), label: solution[:label].value, comment: solution[:comment].value})
      end
      return results
    rescue => exception
      puts exception.inspect
      return []
    end
  end

  def list_relations(class_id, ontology_id = nil)
    begin
      ontology = Ontology.find_by(getOntologyFindCondition(class_id, ontology_id))
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      relation_properties_filter = ontology.relation_filter
      results = []
      query = sparql.query("
      select ?property ?label ?comment (group_concat(?type;separator=',') as ?types)
      where {
          #{formatId(class_id)} rdfs:subClassOf* ?class .
          ?property #{ontology.domainkey} ?class .
          ?property rdfs:label ?label .
          ?property rdfs:comment ?comment .
          ?property #{ontology.rangekey} ?type .
          #{relation_properties_filter}
      }
      group by ?property ?label ?comment")
      query&.each_solution do |solution|
        results.push({ property: solution[:property].value, types: solution[:types].value.split(','), label: solution[:label].value, comment: solution[:comment].value})
      end
      return results
    rescue => exception
      puts exception.inspect
      return []
    end
  end

  def search_loaded_components(searchText, semantic_component)
      queryClasses = "
      select distinct ?component
      where {
        ?entityId rdf:type ?component .
        FILTER(?component != schema:NoteDigitalDocument)
      }"
      queryRelations = "
      select distinct ?component
      where {
        ?entityId ?component ?target .
        FILTER(?target != schema:NoteDigitalDocument)
      }"
      statement = semantic_component == "class" ? queryClasses : queryRelations 
      execute_sparql(statement)
  end

  def upload_ontology(ontology)
    url = ERB::Util.url_encode(ontology.url)
    %x{ curl --digest --user "#{@user}":"#{@password}" --verbose --url "\"#{@host}\"/sparql-graph-crud-auth?graph-uri=\"#{url}\"" -T "#{ontology.graph_file.current_path}" }
    configure_ontology(ontology)
  end

  def configure_ontology(ontology)
    # create prefix
    puts "about to change prefix on virtuoso\n"
    isql_host = URI.parse(@host)
    %x{ "#{@isql_path}" "#{isql_host.host}":1111 "#{@user}" "#{@password}" exec="DB.DBA.XML_SET_NS_DECL ('\"#{ontology.prefix}\"', '\"#{ontology.url}\"', 2);" }
  end

  private
    def do_query(query, format = "text/plain", serialize_reponse_format = format)
      puts("About to run the next SPARQL statement =>\n", query)
      httpClient = HttpClient.new(@host, {}, serialize_reponse_format)
      httpClient.do_post('/sparql', {}, {"query" => query, "default-graph-uri" => @graph, "format" => format })
    end

    def jsonldToRdf(jsonld_string)
      input = JSON.parse(jsonld_string)
      graph = RDF::Graph.new << JSON::LD::API.toRdf(input)
      graph.dump(:ntriples, validate: false)
    end

    def rdfToJsonld(rdf_string, element_id, is_container = false)
      graph = RDF::Graph.new << RDF::Turtle::Reader.new(rdf_string)
      context = JSON.parse %({
        "@context": {
          "schema":   "http://schema.org/",
          "rdf":  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
          "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
          "transcriptor": "#{ @graph }/"
        }
      })
      compacted = nil
      JSON::LD::API::fromRdf(graph) do |expanded|
        compacted = JSON::LD::API.compact(expanded, context['@context'])
      end
      flatCompacted(compacted, element_id, is_container)
    end

    def flatCompacted(compacted, element_id, is_container = false)
      mainElement = nil
      for graphElement in compacted['@graph'] || []
        if (graphElement["@id"] == element_id)
          mainElement = graphElement
          mainElement['@context'] = compacted['@context']
          return is_container ? flatCompacted(compacted, mainElement['schema:mainEntity']['@id'], false) : mainElement
        end
      end
      return compacted
    end

    def getPrefixes()
      prefixes = (Ontology.all.map { |ontology| "PREFIX #{ontology.prefix}: <#{ontology.url}>" }).join("\n")
      " 
        PREFIX transcriptor: <#{ @graph }/>
        PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        #{prefixes}
      "
    end

    def sanitizeFilter(filter)
      sanitizedFilter = {}
      filter.each do |key, value|
        entitySanitized = ActiveRecord::Base.connection.quote(value)
        if (value && entitySanitized && entitySanitized != '')
          sanitizedFilter[key] = entitySanitized
        end
      end
      return sanitizedFilter
    end

    def getEntityItem(jsonld_hash, entityId)
      schemedEntityId = "transcriptor:#{entityId.split('/').last}" 
      jsonld_hash['@graph'].find{ |entityItem| entityItem['@id'] == schemedEntityId }
    end

    # Iterates over object taking relationships ID's and nesting that to make one compact object
    def compressEntityRelations(jsonld_hash, entityId)
      graph = jsonld_hash['@graph']
      entity = getEntityItem(jsonld_hash, entityId)
      entity.each do |property, value|
        if(value.is_a?(Hash) && value["@id"])
          entityProperty = graph.find{ |entityItem| entityItem['@id'] == value["@id"] }
          entity[property] = (entityProperty && (entity['@id'] == entityProperty["@id"])) ? { "@id" => entity['@id'] } : entityProperty
        elsif value.is_a?(Array)
          processedArray = []
          value.each do | arrayMember |
            processedArray.push(arrayMember["@id"] ? graph.find{ |entityItem| entityItem['@id'] == arrayMember["@id"] } : arrayMember)
          end
          entity[property] = processedArray
        end
      end
    end

    def getEntityTypes(filter)
      if(filter['entityType'])
        classes = list_classes(nil, filter['entityType'], true)
        if classes
          return filter['hierarchical'] ? classes.map { |entity| formatId(entity[:id]) } : [filter['entityType']]
        else
          return nil
        end
      end
      return nil
    end

    # def getSchemaReference(stringReference)
    #   stringReference.gsub(/<|>/, '').gsub(/http:\/\/schema.org\//, 'schema:')
    # end

    def getTranscriptorReference(stringReference)
      stringReference.gsub(/<|>/, '').gsub(@graph + "/", 'transcriptor:')
    end

    def formatId(id)
      id.match(/https?:\/\/[\S]+/) ? "<#{id}>" : id
    end

    def getOntologyFindCondition(id, ontology_id)
      if ontology_id != nil
        { :id => ontology_id }
      elsif id.match(/https?:\/\/[\S]+/)
         { :url => id[/.*\//].chop }
      else
        { :prefix => id.split(':').first }
      end
    end

    def getOntology(ontology_id, entity_id)
      ontologies = Ontology.all
      if ontology_id != nil
        ontologies.find { |ontology| ontology.id == ontology_id }
      elsif entity_id.match(/https?:\/\/[\S]+/)
        ontologies.find { |ontology| entity_id.match(ontology.url) }
      else
        ontologies.find { |ontology| ontology.prefix == entity_id.split(':').first }
      end
    end

    def splitOntologyFromId(id)
      id.match(/https?:\/\/[\S]+/) ? id[/.*\//].chop : id.split(':').first
    end

    def execute_sparql(statement, graph = @graph)
      begin
        puts("About to run the next SPARQL statement =>\n", statement)
        results = []
        sparql = SPARQL::Client.new("#{@host}/sparql", { graph: graph })
        query = sparql.query(statement)
        query&.each_solution do |solution|
          result = {}
          solution.each do |name, solutionValue|
            result[name] =  solutionValue.value
          end
          results.push(result)
        end
        return results
      rescue => exception
        puts exception.inspect
        return []
      end
    end
end
