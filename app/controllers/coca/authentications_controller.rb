module Coca
  class AuthenticationsController < ::RocketPants::Base
    def self.helper(*args); end
    include Devise::Controllers::Helpers

    before_filter :require_valid_servant!
    before_filter :authenticate_user!

    def show
      expose current_user
    end

  protected

    def require_valid_servant!
      Coca.valid_servant?(request.remote_ip, params[:key])
    end
    
  end
end