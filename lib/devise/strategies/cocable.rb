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
        valid_for_params_auth? || valid_for_cookie_auth?
      end

      def authenticate!
        resource = nil
        response = nil
        
        if authentication_hash
          response = delegate(authentication_hash.merge(:password => password))
        else
          response = delegate({:auth_token => cookie.token})
        end
        
        if response
          # coincidentally, rocket_pants likes to store a rest object under :response
          user_data = response["response"]
          user_data.symbolize_keys!
          resource = mapping.to.where(:uid => user_data[:uid]).first_or_create
          resource.update_attributes(user_data.except(:uid))
        end
        success!(resource) if resource && resource.persisted?
      end
      
      def delegate(credentials)
        rocket_package = nil
        Coca.masters.each do |master|
          rocket_package = master.authenticate(scope, credentials)
          break if rocket_package
        end
        # Rocket_pants passes the main REST object the :response value
        # which leaves us with this bit of dodgy unpacking
        rocket_package.parsed_response
      end

    private
      # AuthCookie takes care of the naming and signing of cookies for each warden scope.
      # All we need is the token contained in the cookie for this scope, if there is one.
      #
      def cookie
        @cookie ||= Coca::AuthCookie.new(cookies, scope)
      end
      
      def valid_for_cookie_auth?
        cookie.valid?
      end

    end
  end
end

Warden::Strategies.add(:cocable, Devise::Strategies::Cocable)
