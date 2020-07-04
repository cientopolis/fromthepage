class Api::OntologyController < Api::ApiController

    before_action :set_ontology, only: [:update, :destroy]

    def create
        @ontology = Ontology.new(ontology_params)
        if @ontology.save
        render_serialized ResponseWS.ok("api.ontology.create.success",@ontology,alert)
        else
            render_serialized ResponseWS.default_error
        end
    end

    def update
        @ontology.update_attributes(ontology_params)
        render_serialized ResponseWS.ok("api.ontology.update.success",@ontology)
    end

    def destroy
        @ontology.destroy
        render_serialized ResponseWS.ok("api.ontology.destroy.success",@ontology)
    end
    
    
    def list
        @ontologies = Ontology.all
        response_serialized_object @ontologies
    end

    private
        def set_ontology
            @ontology = Ontology.find(params[:id])
            raise ActiveRecord::RecordNotFound unless @ontology
        end

        def ontology_params
            params[:ontology].permit(:name,:description,:url,:domainkey,:rangekey,:prefix,:literal_type)
        end
end