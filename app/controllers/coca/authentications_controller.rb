module Coca
  class AuthenticationsController < RocketPants::Base
    include Devise::Controllers::Helpers

    before_filter :require_valid_servant!
    before_filter :allow_params_authentication!

    def show
      scope = params[:scope].to_sym      
      if user = warden.authenticate(:scope => scope)
        expose user
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