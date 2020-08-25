require_relative '../http-client/http-client'
require_relative '../schema_helper'
require_relative 'utils/rdf-utils'
require "base64"
require 'json/ld'
require 'rdf/turtle'
require 'sparql/client'

class VirtuosoClient

  TRANSCRIPTOR_CLASSES = [
    'transcriptor:Collection',
    'transcriptor:Work', 
    'transcriptor:Page', 
    'transcriptor:Layer', 
    'transcriptor:Mark'
  ]

  def initialize()
    @host = ENV['VIRTUOSO_HOST']
    @collection = ENV['VIRTUOSO_COLLECTION']
    @graph = ENV['VIRTUOSO_GRAPH']
    @user = ENV['VIRTUOSO_USER']
    @password = ENV['VIRTUOSO_PASSWORD']
    @isql_path = ENV['VIRTUOSO_ISQL_PATH'] || "#{Dir.pwd}/bin/isql"
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
      #{ getRdfPrefixes() }
      
      INSERT IN GRAPH <#{ @graph }> { 
        #{formatId(subject_id)} #{formatId(predicate_id)} #{formatId(object_id)} .
      }"
      return do_query(query)
    end
    return nil
  end

  def update(jsonld_string_old, jsonld_string_new)
    # "Authorization": "Basic " + Base64.strict_encode64(@user + ":" + @password),
      headers = {
          "Content-Type": "application/sparql-query"
      }
      httpClient = HttpClient.new(@host, headers, 'raw')
      rdf_string_old = jsonldToRdf(jsonld_string_old)
      rdf_string_new = jsonldToRdf(jsonld_string_new)
      if rdf_string_old != rdf_string_new
        query = "
          WITH <#{ @graph }>
          DELETE { #{rdf_string_old} }
          INSERT { #{rdf_string_new} }
        "
        do_query(query)

        old_id = JSON.parse(jsonld_string_old)['@id']
        new_id = JSON.parse(jsonld_string_new)['@id']
        if old_id != new_id
          updateSlugQuery = "
            WITH <#{@graph}>
            INSERT {
              ?entityId ?propertyId ?newId
            }
            where {{
              select ?entityId ?propertyId ?newId
              where {
                ?entityId ?propertyId ?oldId .
                bind(#{formatId(new_id)} As ?newId) .
                FILTER(?oldId = #{formatId(old_id)})
              }
            }}
            DELETE {
              ?entityId ?propertyId ?oldId
            }
            where{{
              select ?entityId ?propertyId ?oldId
              where {
                ?entityId ?propertyId ?oldId .
                FILTER(?oldId = #{formatId(old_id)})
              }
            }}
          " 
          do_query(updateSlugQuery)
        end
      end
  end

  def listSemanticContributions(filter = {})
    begin
      matchedEntityTypes = getEntityTypes(filter)
      sanitizedFilter = filter
      # entityType = (sanitizedFilter['entityType'] != nil) ? "FILTER (?entityType = #{ formatId(filter['entityType']) }) ." : ''
      entityType = (matchedEntityTypes != nil) ? "FILTER (?entityType IN (#{ matchedEntityTypes.join(',') }) && ?entityType != transcriptor:Mark) " : "FILTER (?entityType != transcriptor:Mark) "
      includeMatchedProperties = filter['includeMatchedProperties']
      matchAllConditions = filter['matchAllConditions'] == true
      conditions = [
        {'propertyValue': "regex(?propertyValue, '#conditionValue', 'i')"},
        {'propertyName': "regex(?entityMatchingProperty, '#conditionValue', 'i')"},
        {'entityTypeLike': "regex(?entityType, '#conditionValue', 'i')"}
      ]
      statement = "
          #{ getRdfPrefixes() }

          SELECT DISTINCT ?idNote ?entityType ?idMainEntity #{ includeMatchedProperties ? "(group_concat(?entityMatchingProperty;separator=',') as ?entityMatchingProperties)": '' }
          WHERE {
            ?idNote rdf:type transcriptor:Mark .
            ?idNote transcriptor:mainEntity ?idMainEntity .
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
        #{ getRdfPrefixes() }

        SELECT DISTINCT ?idNote 
        WHERE {
            ?idNote rdf:type transcriptor:Mark .
            ?idNote transcriptor:mainEntity #{ getTranscriptorReference(filter['entityId']) } .
        }
    "
    do_query(query, 'json')&.results || { :bindings => [] }
  end

  def listEntities(filter)
    matchedEntityTypes = getEntityTypes(filter)
    sanitizedFilter = sanitizeFilter(filter)
    entityType = (matchedEntityTypes != nil) ? "FILTER (?entityType IN (#{ matchedEntityTypes.join(',') }) && ?entityType != transcriptor:Mark) " : "FILTER (?entityType != transcriptor:Mark) "
    # propertyValue = (sanitizedFilter['labelValue'] != nil) ? "FILTER regex(?entityLabel, #{ sanitizedFilter['labelValue'] }, 'i') " : ''
    includeMatchedProperties = filter['includeMatchedProperties']
    limit = (sanitizedFilter['limit']  != nil) ? "LIMIT #{ sanitizedFilter['limit'] }" : ''
    matchAllConditions = filter['matchAllConditions']

    conditions = [
      {'labelValue': "regex(?entityLabel, '#conditionValue', 'i')"},
      {'propertyValue': "regex(?propertyValue, '#conditionValue', 'i')"},
      {'propertyName': "regex(?entityProperty, '#conditionValue', 'i')"},
      {'entityTypeLike': "regex(?entityType, '#conditionValue', 'i')"}
    ]

    statement = "
        #{ getRdfPrefixes() }

        SELECT DISTINCT ?entityId ?entityType ?entityLabel #{ includeMatchedProperties ? "(group_concat(?entityProperty;separator=',') as ?entityProperties)": '' }
        WHERE {
            ?entityId rdf:type ?entityType .
            ?entityId rdfs:label ?entityLabel.
            ?entityId ?entityProperty ?propertyValue .
            #{ entityType }
            #{constructQueryFilters(filter, conditions)}
            #{constructFilters(filter, conditions, matchAllConditions)}
            #{default_type_filter("?entityType")}
        }
        #{limit}
    "
    execute_sparql(statement)
    # do_query(statement, 'json')&.results || { :bindings => [] }
  end

  def describeEntity(entityId, useDefaultGraph = false)
    # entityIdQuery = useDefaultGraph ? "#{@graph}#{entityId}" : entityId
    entityIdQuery = is_prefixed(entityId) ? entityId : "#{@graph}#{entityId}"

    query = "
      #{ getRdfPrefixes() }

      DESCRIBE <#{ entityIdQuery }> ?p ?q
      WHERE {
        <#{ entityIdQuery }> ?p ?q
      }
    "
    response = do_query(query)
    (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, entityId), entityId) : nil
  end

  def describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    # idSemanticContributionQuery = useDefaultGraph ? "#{@graph}#{idSemanticContribution}" : idSemanticContribution
    idSemanticContributionQuery = is_prefixed(idSemanticContribution) ? idSemanticContribution : "#{@graph}#{idSemanticContribution}"

    query = "
        #{ getRdfPrefixes() }

        DESCRIBE ?mainEntityId ?p ?q
        WHERE {
          <#{idSemanticContributionQuery}> transcriptor:mainEntity ?mainEntityId .
          ?mainEntityId ?p ?q .
        }
    "
    response = do_query(query)
    semanticContribution = (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, idSemanticContribution), idSemanticContribution) : nil
    entityId = semanticContribution ? semanticContribution['transcriptor:mainEntity']['@id'] : nil
    if entityId
      entityId = entityId.split(':').last
      return (entity = response["data"].body) ? compressEntityRelations(rdfToJsonld(entity, entityId), entityId) : nil
    end
    return nil
    # (entity = response["data"].body) ? rdfToJsonld(entity, "transcriptor:#{idSemanticContribution}", true) : nil
  end

  def list_classes(ontology_id, parent = nil, include_parent = false)
    begin
      ontology = getOntology(ontology_id, parent)
      results = []
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      parentInclusionFilter = include_parent ? '*' : ''
      parentFilter = parent ? "?classId rdfs:subClassOf#{parentInclusionFilter} #{formatId(parent)} ." : "FILTER NOT EXISTS { ?classId rdfs:subClassOf ?parentClass . }"
      statement = "
      select ?label ?comment ?classId
      where {
        ?classId rdfs:label ?label.
        optional { ?classId rdfs:comment ?commentOptional }.
        ?classId rdf:type #{ontology.class_type}.
        bind(coalesce(?commentOptional, '') As ?comment) .
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

  def list_parent_classes(ontology_id, child = nil, include_child = false)
      if(!child)
        return []
      end
      ontology = getOntology(ontology_id, child)
      results = []
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      childInclusionFilter = include_child ? '*' : '+'
      childFilter = "#{formatId(child)} rdfs:subClassOf#{childInclusionFilter}  ?classId."
      statement = "
      select ?label ?comment ?classId ?parentClassId
      where {
        ?classId rdfs:label ?label.
        optional { ?classId rdfs:comment ?commentOptional }.
        ?classId rdf:type #{ontology.class_type}.
        bind(coalesce(?commentOptional, '') As ?comment) .
        optional { ?classId rdfs:subClassOf ?parentClassIdOptional }.
        bind(coalesce(?parentClassIdOptional , '') As ?parentClassId) 
        FILTER NOT EXISTS {
          ?classId rdf:type #{ontology.literal_type}
        }.
        #{childFilter}
      }
      group by ?label ?comment ?classId"
      execute_sparql(statement, ontology.url)
  end

  def search_classes(searched_text, ontologyModel, ontology_id = nil)
    ontology = ontologyModel ? ontologyModel : getOntology(ontology_id)
    statement = "
    select ?label ?comment ?classId
    where {
      ?classId rdfs:label ?label.
      optional { ?classId rdfs:comment ?commentOptional }.
      ?classId rdf:type #{ontology.class_type}.
      bind(coalesce(?commentOptional, '') As ?comment) .
      FILTER NOT EXISTS {
        ?classId rdf:type #{ontology.literal_type}
      }.
      FILTER regex(?label, '#{searched_text}', 'i')
    }"
    execute_sparql(statement, ontology.url)
  end

  def list_properties(class_id, ontology_id = nil)
    begin
      ontology = getOntology(ontology_id, class_id)
      sparql = SPARQL::Client.new("#{@host}/sparql", { graph: ontology.url })
      literal_properties_filter = ontology.literal_filter
      results = []
      statement = "
      select ?property ?label ?comment (group_concat(?type;separator=',') as ?types)
      where {
          #{formatId(class_id)} rdfs:subClassOf* ?class .
          ?property #{ontology.domainkey} ?class .
          ?property rdfs:label ?label .
          ?property rdfs:comment ?commentOptional .
          ?property #{ontology.rangekey} ?type .
          #{literal_properties_filter}
          bind(coalesce(?commentOptional, '') As ?comment) .
      }
      group by ?property ?label ?comment"
      puts statement
      query = sparql.query(statement)
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
      ontology = getOntology(ontology_id, class_id)
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
        FILTER(?component != transcriptor:Mark) .
        FILTER regex(?component, '#{searchText}', 'i') .
      }"
      queryRelations = "
      select distinct ?component
      where {
        ?entityId ?component ?target .
        FILTER(?target != transcriptor:Mark) .
        FILTER regex(?component, '#{searchText}', 'i') .
      }"
      statement = semantic_component == "class" ? queryClasses : queryRelations 
      execute_sparql(statement)
  end

  def export_as_rdf(collection_id, work_id = nil)
    collectionFilter = formatId(collection_id)
    workFilter = work_id ? formatId(work_id) : '?work'
    query = "
      construct {
          ?s ?p ?o
      } where {{
          select ?s ?p ?o {
              {
                  select ?s ?p ?o (?s AS ?collection)
                  where {
                      ?s ?p ?o .
                      filter(?s = #{collectionFilter})
                  }
              } union {
                  select ?s ?p ?o (?s AS ?work)
                  where {
                      ?s transcriptor:belongsToCollection ?collection .
                      ?s ?p ?o .
                      filter(?collection = #{collectionFilter})
                      filter(?s = #{work_id ? workFilter : '?s'})
                  }
              } union {
                  select ?s ?p ?o (?s AS ?page)
                  where {
                      ?s transcriptor:belongsToWork #{workFilter} .
                      ?s ?p ?o .
                      filter exists {
                          #{workFilter} transcriptor:belongsToCollection #{collectionFilter} .
                      }
                  }
              } union {
                  select ?s ?p ?o (?s AS ?layer)
                  where {
                      ?s transcriptor:belongsToPage ?page .
                      ?s ?p ?o .
                      filter exists {
                      #{workFilter} transcriptor:belongsToCollection #{collectionFilter} .
                      ?page transcriptor:belongsToWork #{workFilter} .
                      }
                  }
              } union {
                  select ?s ?p ?o (?s AS ?mark)
                  where {
                      ?s transcriptor:belongsToLayer ?layer .
                      ?s ?p ?o .
                      filter exists {
                      #{workFilter} transcriptor:belongsToCollection #{collectionFilter} .
                      ?page transcriptor:belongsToWork #{workFilter} .
                      ?layer transcriptor:belongsToPage ?page .
                      }
                  }
              } union {
                  select ?s ?p ?o (?s AS ?entity)
                  where {
                      ?mark transcriptor:mainEntity ?s .
                      ?s ?p ?o .
                      filter exists {
                      #{workFilter} transcriptor:belongsToCollection #{collectionFilter} .
                      ?page transcriptor:belongsToWork #{workFilter} .
                      ?layer transcriptor:belongsToPage ?page .
                      ?mark transcriptor:belongsToLayer ?layer .
                      }
                  }
              }
          }
      }}
    "
    exported_data = do_query(query, 'application/rdf+xml')
    RdfUtils.format_export(exported_data['data'].body, get_prefixes)
  end

  def get_transcriptor_ontology
    query = "
      select ?predicate ?value
      where { <#{@graph}> ?predicate ?value }
    "
    execute_sparql(query)
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
    # command = "#{@isql_path} #{isql_host.host}:1111 #{@user} #{@password} exec=\"DB.DBA.XML_SET_NS_DECL (\"#{ontology.prefix}\", \"#{ontology.url}\", 2);\" "
    %x{ "#{@isql_path}" "#{isql_host.host}":1111 "#{@user}" "#{@password}" exec="DB.DBA.XML_SET_NS_DECL ('\"#{ontology.prefix}\"', '\"#{ontology.url}\"', 2);" }
  end

  def get_prefixes
    prefixes = {
      :rdf => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      :rdfs => "http://www.w3.org/2000/01/rdf-schema#",
      :transcriptor => @graph,
    }
    Ontology.all
    for ontology in Ontology.all do
      prefixes[ontology.prefix.to_sym] = ontology.url
    end
    return prefixes
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
      # context = JSON.parse %({
      #   "@context": {
      #     "schema":   "http://schema.org/",
      #     "rdf":  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      #     "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
      #     "transcriptor": "#{ @graph }"
      #   }
      # })
      context = JSON.parse(SemanticHelper.get_prefixes.to_json)
      compacted = nil
      JSON::LD::API::fromRdf(graph) do |expanded|
        compacted = JSON::LD::API.compact(expanded, context)
      end
      flatCompacted(compacted, element_id, is_container)
    end

    def flatCompacted(compacted, element_id, is_container = false)
      mainElement = nil
      for graphElement in compacted['@graph'] || []
        if (graphElement["@id"] == element_id)
          mainElement = graphElement
          mainElement['@context'] = compacted['@context']
          return is_container ? flatCompacted(compacted, mainElement['transcriptor:mainEntity']['@id'], false) : mainElement
        end
      end
      return compacted
    end

    def getRdfPrefixes
      prefixes = (Ontology.all.map { |ontology| "PREFIX #{ontology.prefix}: <#{ontology.url}>" }).join("\n")
      " 
        PREFIX transcriptor: <#{ @graph }>
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
    
    def getTranscriptorReference(stringReference)
      stringReference.gsub(/<|>/, '').gsub(@graph, 'transcriptor:')
    end

    def formatId(id)
      id.match(/https?:\/\/[\S]+/) ? "<#{id}>" : id
    end

    def getOntology(ontology_id, entity_id = nil)
      if (ontology_id == nil && entity_id == nil)
        return nil
      end
      ontologies = Ontology.all
      if ontology_id != nil
        ontologies.find { |ontology| ontology.id == Integer(ontology_id) }
      elsif entity_id.match(/https?:\/\/[\S]+/)
        ontologies.find { |ontology| entity_id.match(ontology.url) }
      else
        ontologies.find { |ontology| ontology.prefix == entity_id.split(':').first }
      end
    end

    def is_prefixed(entity_id)
      if (entity_id == nil)
        return false
      end
      ontologies = findOntologies(true)
      if entity_id.match(/https?:\/\/[\S]+/)
        ontologies.any? { |ontology| entity_id.match?(ontology.url) }
      else
        ontologies.any? { |ontology| ontology.prefix == entity_id.split(':').first }
      end
    end

    def findOntologies(includeDefaultGraph = false)
      ontologies = Ontology.all
      if (includeDefaultGraph)
        ontologies.push(OpenStruct.new( :prefix => "transcriptor", :url => @graph ))
      end
      return ontologies
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

    # this filter prevents to list default ontology types
    def default_type_filter(type_variable)
      return "FILTER (#{type_variable} NOT IN (#{TRANSCRIPTOR_CLASSES.join(',')}))."
    end
end
