class AuthenticationsController < RocketPants::Base
  respond_to :json
  before_filter :require_valid_servant!
  before_filter :authenticate_user!

  def new
    expose @user
  end

protected

  def require_valid_servant!
    Coca.valid_servant?(request.host, params[:key])
  end
  
end
