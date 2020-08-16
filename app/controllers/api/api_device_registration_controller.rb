class Api::ApiDeviceRegistrationController < Devise::RegistrationsController
  
  include I18nHelper
  
  before_action :set_locale
  
  def render_serialized(object, properties = [], methods = [])
    render json: object, :include => properties, :methods => methods
  end
  
  def response_serialized_object(object)
    render_serialized ResponseWS.default_ok(object)
  end
  
  private
    def _not_signed_error
      return ResponseWS.simple_error('api.session.not_allowed')
    end
end

