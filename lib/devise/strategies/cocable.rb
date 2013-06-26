require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    
    # The cocable strategy will look for a user in two places: 
    # in a domain cookie set by one of our peers and verified by an upstream app
    # or in credentials supplied to us and verified by an upstream app
    #
    # (If the credentials matched locally, we wouldn't usually get to this strategy)

    class Cocable < Authenticatable
      def valid?
        valid_for_params_auth? || cookie.valid?
      end

      def authenticate!
        resource = nil
        response = nil
        
        if authentication_hash
          response = delegate(authentication_hash)
        else
          response = delegate({:auth_token => cookie.token})
        end
        
        if response
          resource = mapping.to.where(:uid => response[:uid]).first_or_create
          resource.update_attributes(response.except(:uid))
        end
        
        success!(resource) if resource# && validate(resource)
      end
      
      def delegate(credentials)
        response = nil
        Coca.masters.each do |master|
          response = master.authenticate(scope, credentials)
          break if response
        end
        response
      end

    private
      # AuthCookie takes care of the naming and signing of cookies for each warden scope.
      # All we need is the token contained in the cookie for this scope, if there is one.
      #
      def cookie
        @cookie ||= Coca::AuthCookie.new(cookies, scope)
      end

    end
  end
end

Warden::Strategies.add(:cocable, Devise::Strategies::Cocable)
