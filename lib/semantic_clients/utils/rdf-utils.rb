require 'rdf/rdfxml'

class RdfUtils

    def self.puts_separator(elements, element_type)
        elements.prepend_child("<!-- Definition of #{element_type} elements -->")
    end

    def self.format_export(exported_data, prefixes = nil)
        statements = []

        RDF::RDFXML::Reader.new( exported_data ) do |reader|
            reader.each_statement do |statement|
                statements.push(statement)
            end
        end

        rdfxmlString = RDF::RDFXML::Writer.buffer(prefixes: {
            rdfs: "http://www.w3.org/2000/01/rdf-schema#",
            transcriptor: "http://transcriptor.com/",
            schema: "http://schema.org/"}, 
            attributes: :none, 
            max_depth: 0
        ) do |writer|
            for statement in statements do
                writer << statement
            end
        end

        doc = Nokogiri::XML(rdfxmlString) do |config|
            config.noblanks
        end

        elements = doc.at('//rdf:RDF')
        elements_order = ['Collection', 'Work', 'Page', 'Layer', 'Mark']

        for element_type in elements_order.reverse do
            matched_elements = elements.search("./transcriptor:#{element_type}")
            if(element_type == "Mark"  && matched_elements.length > 0) 
                puts_separator(elements, "Entity")
            end
            matched_elements.sort{|e1, e2| e2.attr('rdf:about') <=> e1.attr('rdf:about')}.each do |table|
                elements.prepend_child(table)
            end
            if(matched_elements.length > 0) 
                puts_separator(elements, element_type)
            end
        end

        return doc.to_xml
    end

end