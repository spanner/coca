module Coca
  class AuthenticationsController < ::ApplicationController
    include Devise::Controllers::Helpers
    respond_to :json

    # Check that request is coming up the coca chaing
    before_filter :require_valid_servant!

    # Act like a devise SessionController.
    before_filter :allow_params_authentication!

    def show
      if scope = params[:scope].to_sym && user = warden.authenticate(:scope => scope)
        respond_with @user, :format => :coca
      else
        head :unauthorized
      end
    end

  protected

    def require_valid_servant!
      Coca.valid_servant?(request.remote_ip, params[:key])
    end

  end
end