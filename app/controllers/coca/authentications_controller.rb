module Coca
  class AuthenticationsController < RocketPants::Base
    respond_to :json
    before_filter :require_valid_servant!

    def check
      scope = params[:scope] || 'user'
      if warden.authenticate(:scope => params[:scope])
        expose resource
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