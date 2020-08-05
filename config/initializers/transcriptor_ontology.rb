require_relative "../../lib/semantic_helper"

transcriptor_ontology = SemanticHelper.get_transcriptor_ontology
if (transcriptor_ontology && transcriptor_ontology.length == 0)
    Rails.logger.info("Transcriptor Ontology not found. Proceeding to create it.")
    ontology = File.read("config/ontology/transcriptor_ontology.json")
    SemanticHelper.insert(ontology)
end