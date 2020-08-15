class Api::LoginController < Api::ApiController

  def public_actions
    return [:login,:functions]
  end

  def login
    username = params[:username]
    password = params[:password]
    user = User.find_for_authentication(["login = :value OR lower(email) = lower(:value)", { :value => username}])
    if (user != nil && user.valid_password?(password))
      # Record login event
      alert = GamificationHelper.loginEvent(user.email)
      render_serialized ResponseWS.ok('api.login.success',user,alert)
    else
      render_serialized ResponseWS.simple_error('api.login.fail')
    end
  end


  def functions
    user_id = params[:id]
    if user_id != nil
      user = User.find_by(id:user_id)
      if (user != nil )
        # Record login event
        functions = user.role.functionrole
        render_serialized ResponseWS.ok('api.login.success',functions)
      else
        functions = Functionrole.where(public: true)
        render_serialized ResponseWS.ok('api.login.success',functions)
      end
    else
        functions = Functionrole.where("public is true and uri is not null and uri <> ''")
        render_serialized ResponseWS.ok('api.login.success',functions)
    end
  end 


end
