# handles administrative tasks for the collection object
class Api::CollectionController < Api::ApiController
  
  before_action :set_collection, :only => [:show, :edit, :update, :destroy, :contributors, :new_work, :export_as_rdf,:add_owners,:owners,:users]
  before_filter :load_settings, :only => [:edit, :update, :upload]
  
  def public_actions
    return [:show,:show_works,:export_as_rdf]
  end
  
  ### Endpoints Methods ###
  
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    @collection.owner = current_user
    if @collection.save
      
      # record activity on gamification services 
      alert = GamificationHelper.createCollectionEvent(current_user.email)
      
      # flash[:notice] = 'Collection has been created'
      # if request.referrer.include?('sc_collections')
        # session[:iiif_collection] = @collection.id
        # ajax_redirect_to(request.referrer)
      # else
        # ajax_redirect_to({ controller: 'dashboard', action: 'startproject', collection_id: @collection.id })
      # end
      render_serialized ResponseWS.ok('api.collection.create.success',@collection,alert)
    else
      # render action: 'new'
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    if params[:collection][:slug] == ""
      @collection.update(params[:collection].except(:slug).except(:picture))
      title = @collection.title.parameterize
      @collection.update(slug: title)
    else
      @collection.update(params[:collection].except(:picture))
    end
    if (params[:collection][:picture] != nil && params[:collection][:picture].instance_of?(ActionDispatch::Http::UploadedFile))
      @collection.update(picture: params[:collection][:picture])
    end
    if @collection.save!
      # flash[:notice] = 'Collection has been updated'
      # redirect_to action: 'edit', collection_id: @collection.id
      
      render_serialized ResponseWS.ok('api.collection.update.success',@collection)
    else
      # render action: 'edit'
      render_serialized ResponseWS.default_error
    end
  end
  
  def destroy
    @collection.destroy
    # redirect_to dashboard_owner_path
    render_serialized ResponseWS.ok('api.collection.destroy.success',@collection)
  end
  
  def show    
    response_serialized_object @collection
  end
  
  def show_works
    # if @collection.restricted
    #   ajax_redirect_to dashboard_path unless user_signed_in? && @collection.show_to?(current_user)
    # end    
    @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
    response_serialized_object @works
  end
  
  def list_own 
    begin
      @collections = current_user.all_owner_collections
    rescue => exception
      @collections = []
    end
    response_serialized_object @collections
  end
  
  ### Filter Methods ###
  
  def load_settings
    @main_owner = @collection.owner
    @owners = [@main_owner] + @collection.owners
    @nonowners = User.order(:display_name) - @owners
    @nonowners.each { |user| user.display_name = user.login if user.display_name.empty? }
    # Uncomment when token auth is ready
    # @works_not_in_collection = current_user.owner_works - @collection.works
    @collaborators = @collection.collaborators
    @noncollaborators = User.order(:display_name) - @collaborators - @collection.owners
  end


  def collections_list
    @collections = Collection.all
    response_serialized_object @collections
  end

  def export_as_rdf
    file_content = @collection.export_as_rdf['data'].body
    send_data file_content, :filename => "#{@collection.slug}.rdf"
  end

  def add_owner
    @user.owner = true
    @user.save!
    @collection.owners << @user
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def add_owners
    error = false
    for userparam in params[:users]
      user = User.find_by(:id => userparam[:id])
      if user && !user.admin 
        if user
          if userparam[:isOwner] && !@collection.isOwnerCollection(user) 
            user.owner = true
            user.save!
            @collection.owners << user      
          else    
            @collection.owners.delete(user)
          end
        end
      else
        error = true
      end
    end
    if error
      render_serialized ResponseWS.simple_error('api.collection.addordeleteowner.failadmin')
    else
      #redirect_to action: 'edit', collection_id: @collection.id =end
      render_serialized ResponseWS.ok('api.collection.addordeleteowner.success',@collection.owners)
    end
  end

  def owners
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    @nonowners = User.all - @owners
    render_serialized ResponseWS.ok('api.collection.owners.success',@nonowners)
  end

  def users
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    if params[:search]
        @users = User.search(params[:search]).order(login: :asc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    else
        @users = User.order(login: :asc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    end
    for user in @users
      if @owners.include? user
        user.isOwner = true
      else
        user.isOwner = false
      end
    end
    response_serialized_object_pagination('api.collection.users.success',@users,alert)
    
  end

  private
    def set_collection
      unless @collection
        if Collection.friendly.exists?(params[:id])
          @collection = Collection.friendly.find(params[:id])
        elsif DocumentSet.friendly.exists?(params[:id])
          @collection = DocumentSet.friendly.find(params[:id])
        elsif !DocumentSet.find_by(slug: params[:id]).nil?
          @collection = DocumentSet.find_by(slug: params[:id])
        elsif !Collection.find_by(slug: params[:id]).nil?
          @collection = Collection.find_by(slug: params[:id])
        end
      end
    end


    def set_collection_for_work(collection, work)
      # first update the id on the work
      work.collection = collection
      work.save!
      # then update the id on the articles
      # consider moving this to the work model?
      for article in work.articles
        article.collection = collection
        article.save!
      end
    end
    
end
