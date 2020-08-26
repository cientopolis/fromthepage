class AddFunctions < ActiveRecord::Migration
  def change
    functions = [
            {name:'login',uri:'/login',public:true}, 
            {name:'home',uri:'/home',public:true}, 
            {name:'dashboard',uri:'/dashboard',public:true},  
            {name:'collections',public:true,uri:'/collections/list'},
            {name:'collections',public:false,uri:'/collections/list:create',isadmin:true},
            {name:'work',public:true,uri:'/work'},
            {name:'transcribe',public:true,uri:'/transcribe'},
            {name:'search',public:false,uri:'/search',isadmin:false},
            {name:'startproject:create',public:false,uri:'/startproject:create',isadmin:false},
            {name:'startproject',public:false,uri:'/startproject',isadmin:true},
            {name:'profile',public:false,uri:'/user/profile',isadmin:false},
            {name:'work:activities',public:false,uri:'/work:activities',isadmin:false}, 
            {name:'page-version',public:false,uri:'/page-version',isadmin:false},
            {name:'work:configuration',public:false,uri:'/work:configuration',isadmin:false},
            {name:'transcribe:transcribe',public:false,uri:'/transcribe:transcribe',isadmin:false},
            {name:'collectionslist:config',public:false,uri:'/collections/list:config',isadmin:true},
            {name:'collectionslist:activities',public:false,uri:'/collections/list:activities',isadmin:false}, 
            {name:'ontologies',public:false,uri:'/ontology',isadmin:true},
            {name:'administration',public:false,uri:'/admin',isadmin:true},
            {name:'collection:config',public:false,uri:'/collection:config',isadmin:false},
            {name:'collection:delete',public:false,uri:'/collection:delete',isadmin:true}]

    functionendpoints = [
        {name:'',isAdmin:false,public:true,endpoint:'collection#show'},    
        {name:'',isAdmin:false,public:true,endpoint:'collection#show_works'},
        {name:'',isAdmin:false,public:true,endpoint:'dashboard#startproject'},
        {name:'',isAdmin:false,public:true,endpoint:'login#login'},
        {name:'',isAdmin:false,public:true,endpoint:'login#functions'},
        {name:'',isAdmin:false,public:true,endpoint:'layer#index'},
        {name:'',isAdmin:false,public:true,endpoint:'mark#index'},
        {name:'',isAdmin:false,public:true,endpoint:'mark#list_by_semantic_entity'},
        {name:'',isAdmin:false,public:true,endpoint:'ontology#search_classes'}, 
        {name:'',isAdmin:false,public:true,endpoint:'page#show'},
        {name:'',isAdmin:false,public:true,endpoint:'password#create'},
        {name:'',isAdmin:false,public:true,endpoint:'password#confirm'},
        {name:'',isAdmin:false,public:true,endpoint:'registration#create'},
        {name:'',isAdmin:false,public:true,endpoint:'registration#after_sign_in_path_for'},
        {name:'',isAdmin:false,public:true,endpoint:'registration#destroy'},
        {name:'',isAdmin:false,public:true,endpoint:'registration#update'}, 
        {name:'',isAdmin:false,public:true,endpoint:'schemaOrg#get_schema_type'},
        {name:'',isAdmin:false,public:true,endpoint:'schemaOrg#get_schema_config'},
        {name:'',isAdmin:false,public:true,endpoint:'search#list_semantic_references'},
        {name:'',isAdmin:false,public:true,endpoint:'search#list_semantic_references_by_properties'},
        {name:'',isAdmin:false,public:true,endpoint:'search#list_marks'},
        {name:'',isAdmin:false,public:true,endpoint:'search#search_loaded_components'},
        {name:'',isAdmin:false,public:true,endpoint:'semanticContribution#index'},
        {name:'',isAdmin:false,public:true,endpoint:'aemanticEntity#list'},
        {name:'',isAdmin:false,public:true,endpoint:'aemanticEntity#show'},
        {name:'',isAdmin:false,public:true,endpoint:'aemanticEntity#add_relation'},
        {name:'',isAdmin:false,public:true,endpoint:'semanticOntology#list_classes'},
        {name:'',isAdmin:false,public:true,endpoint:'semanticOntology#list_properties'},
        {name:'',isAdmin:false,public:true,endpoint:'semanticOntology#list_relations'},
        {name:'',isAdmin:false,public:true,endpoint:'transcription#index'},
        {name:'',isAdmin:false,public:true,endpoint:'translation#index'},
        {name:'',isAdmin:false,public:true,endpoint:'work#show'},
        {name:'',isAdmin:false,public:true,endpoint:'work#show_pages'},
        {name:'',isAdmin:true,public:false,endpoint:'collection#create'},
        {name:'',isAdmin:false,public:false,endpoint:'collection#update'},
        {name:'',isAdmin:true,public:false,endpoint:'collection#destroy'}, 
        {name:'',isAdmin:false,public:false,endpoint:'collection#list_own'}, 
        {name:'',isAdmin:false,public:false,endpoint:'collection#load_settings'},
        {name:'',isAdmin:false,public:false,endpoint:'collection#collections_list'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#get_data'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#index'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#startproject'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#owner'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#watchlist'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#recent_work'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#editor'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#guest'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#ownerResponse'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#collectionsOfOwner'},
        {name:'',isAdmin:false,public:false,endpoint:'dashboard#workActivity'},
        {name:'',isAdmin:false,public:false,endpoint:'deed#list'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#create'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#update'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#getByClass'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#show'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#foro_params'},
        {name:'',isAdmin:false,public:false,endpoint:'foro#set_foro'},
        {name:'',isAdmin:false,public:false,endpoint:'layer#list_by_page'},
        {name:'',isAdmin:false,public:false,endpoint:'layer#create'},
        {name:'',isAdmin:false,public:false,endpoint:'layer#update'},
        {name:'',isAdmin:false,public:false,endpoint:'layer#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'layer#show'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#list_by_page'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#list_by_layer'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#list_by_semantic_slug'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#create'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#update'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'mark#show'},
        {name:'',isAdmin:true,public:false,endpoint:'ontology#create'},
        {name:'',isAdmin:true,public:false,endpoint:'ontology#update'},
        {name:'',isAdmin:true,public:false,endpoint:'ontology#destroy'},
        {name:'',isAdmin:false,public:true,endpoint:'ontology#list'},
        {name:'',isAdmin:false,public:false,endpoint:'page#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'page#create'},
        {name:'',isAdmin:false,public:false,endpoint:'page#update'},
        {name:'',isAdmin:false,public:false,endpoint:'page_version#list_by_page'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#create'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#update'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#list'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#listByPublication'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#like'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#dislike'},
        {name:'',isAdmin:false,public:false,endpoint:'publication#set_publication'},
        {name:'',isAdmin:false,public:false,endpoint:'schemaOrg#rdfaToJsonld'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#list_by_mark'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#list_likes_by_user'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#transcription_like_by_user'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#create'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#update'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#like'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#dislike'},
        {name:'',isAdmin:false,public:false,endpoint:'semanticContribution#show'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#mark_page_blank'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#needs_review'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#update_status'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#save_transcription'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#assign_categories'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#save_translation'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#stub_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_correction_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_index_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_review_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_translation_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_translation_review_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcribe#record_translation_index_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#list_by_mark'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#list_likes_by_user'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#transcription_like_by_user'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#create'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#update'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#like'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#dislike'},
        {name:'',isAdmin:false,public:false,endpoint:'transcription#show'},
        {name:'',isAdmin:false,public:false,endpoint:'translation#list_by_mark'},
        {name:'',isAdmin:false,public:false,endpoint:'translation#create'},
        {name:'',isAdmin:false,public:false,endpoint:'translation#update'},
        {name:'',isAdmin:false,public:false,endpoint:'translation#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'translation#like'},
        {name:'',isAdmin:false,public:false,endpoint:'upload#create'},
        {name:'',isAdmin:false,public:false,endpoint:'user#update_profile'},
        {name:'',isAdmin:false,public:false,endpoint:'user#update'},
        {name:'',isAdmin:false,public:false,endpoint:'user#profile'},
        {name:'',isAdmin:false,public:false,endpoint:'user#record_deed'},
        {name:'',isAdmin:false,public:false,endpoint:'user#user_metagame_info'},
        {name:'',isAdmin:false,public:false,endpoint:'work#destroy'},
        {name:'',isAdmin:false,public:false,endpoint:'work#create'},
        {name:'',isAdmin:false,public:false,endpoint:'work#update'},
        {name:'',isAdmin:false,public:false,endpoint:'work#change_collection'},
        {name:'',isAdmin:false,public:false,endpoint:'admin#user_list'},
        {name:'',isAdmin:false,public:false,endpoint:'collection#add_owners'},
        {name:'',isAdmin:false,public:false,endpoint:'collection#owners'},
        {name:'',isAdmin:false,public:false,endpoint:'collection#users'}]

    adminrole = Role.find_by(name: "administrator")
    collaboratorrole = Role.find_by(name: "collaborator")
    functions.each do |function|
        func = Functionrole.find_by(uri: function[:uri])
        if !func
            func = Functionrole.new
        end
        func.uri=function[:uri]
        func.public=function[:public]
        func.name=function[:name]
        if function[:public] || !function[:isadmin]
            func.role=[adminrole,collaboratorrole]
        else
            func.role=[adminrole]
        end
        func.save!
    end

    adminrole = Role.find_by(name: "administrator")
    collaboratorrole = Role.find_by(name: "collaborator")
    functionendpoints.each do |function|
        func = Functionrole.find_by(apiendpoint: function[:endpoint])
        if !func
            func = Functionrole.new
        end
        func.uri=''
        func.public=function[:public]
        func.name=function[:name]
        func.apiendpoint=function[:endpoint]
        if function[:public] || !function[:isAdmin]
            func.role=[adminrole,collaboratorrole]
        else
            func.role=[adminrole]
        end
        func.save!
    end
  end
end