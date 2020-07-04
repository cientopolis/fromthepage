class Ontology < ActiveRecord::Base
    before_validation :set_default_params

    def set_default_params
        self.literal_type = self.literal_type || 'rdfs:Literal'
        self.domainkey = self.domainkey || 'rdfs:domain'
        self.rangekey = self.rangekey || 'rdfs:range'
    end

    def is_typed_literals
        self.rangekey != 'rdfs:range'
    end

    def literal_filter
        typed_properties_filter ="
        ?type rdfs:subClassOf* ?parentPropertyType .
        ?parentPropertyType rdf:type #{self.literal_type} ."
        raw_properties_filter = "filter(?type = rdfs:Literal)"
        self.is_typed_literals ?  typed_properties_filter : raw_properties_filter
    end

    def relation_filter
        typed_properties_filter = "
        filter not exists {  
            ?type rdfs:subClassOf* ?parentPropertyType.
            ?parentPropertyType rdf:type #{self.literal_type}.
        }"
        raw_properties_filter = "
        filter not exists { 
            ?property rdfs:range rdfs:Literal . 
        }"
        self.is_typed_literals ?  typed_properties_filter : raw_properties_filter
    end
end
