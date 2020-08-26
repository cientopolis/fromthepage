class  Api::AdminController < Api::ApiController


    
    def index
        @collections = Collection.all
        @articles = Article.all
        @works = Work.all
        @ia_works = IaWork.all
        @pages = Page.all
        @users = User.all
        @owners = @users.select {|i| i.owner == true}

    end
    
    def user_list
        if params[:search]
            @users = User.search(params[:search]).order(login: :asc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
        else
            @users = User.order(login: :asc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
        end
        response_serialized_object_pagination('api.collection.users.success',@users,alert)
    end

end