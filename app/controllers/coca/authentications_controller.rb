module Coca
  class AuthenticationsController < ::ApplicationController
    include Devise::Controllers::Helpers
    skip_authorization_check if respond_to? :skip_authorization_check
    respond_to :json

    rescue_from "SignedJson::SignatureError", :with => :unauthorized

    # Check that request is coming up the coca chaing
    before_filter :require_valid_servant!

    # Act like a devise SessionController.
    before_filter :allow_params_authentication!

    def show
      if (scope = params[:scope].to_sym) && (@user = warden.authenticate(:scope => scope))
        render :text => @user.to_json(:purpose => :coca)
      else
        head :unauthorized
      end
    end
    
    def unauthorized
      head :unauthorized
    end
    

  protected

    def require_valid_servant!
      Coca.valid_servant?(request.remote_ip, params[:key])
    end

  end
end