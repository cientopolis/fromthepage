class Api::OntologyController < Api::ApiController

    before_action :set_ontology, only: [:update, :destroy, :search_classes]

    def public_actions
        return [:search_classes]
    end

    def create
        @ontology = Ontology.new(ontology_params)
        if @ontology.save
        render_serialized ResponseWS.ok("api.ontology.create.success",@ontology,alert)
        else
            render_serialized ResponseWS.default_error
        end
    end

    def update
        @ontology.update_attributes(ontology_params.except(:graph_file))
        if (params[:ontology][:graph_file] != nil && params[:ontology][:graph_file].instance_of?(ActionDispatch::Http::UploadedFile))
            @ontology.update(graph_file: params[:ontology][:graph_file])
            @ontology.upload_to_store
        end
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

    def search_classes
        params.permit(:search_text)
        if(params.has_key?(:search_text) && params[:search_text] != '')
            response_serialized_object SemanticHelper.search_classes(params[:search_text], @ontology)
        else
            response_serialized_object []
        end
    end

    private
        def set_ontology
            @ontology = Ontology.find(params[:id])
            raise ActiveRecord::RecordNotFound unless @ontology
        end

        def ontology_params
            params[:ontology].permit(:name,:description,:url,:domainkey,:rangekey,:prefix,:literal_type, :class_type, {:ontology_datatypes_attributes => [:id, :semantic_class, :internal_type, :_destroy]}, :graph_file)
        end
end