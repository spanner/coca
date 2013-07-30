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
        
        Rails.logger.warn ">>> Cocable.authenticate!"
        
        # 1. there is an auth cookie and we recognise the auth_token it contains
        
        if cookie && resource = mapping.to.find_for_token_authentication(:auth_token => cookie.token).first
          Rails.logger.warn ">>> got local user from cookie!"
          success!(resource)
        
        # 2. there is an email/password login hash that we can pass up to coca masters
        
        elsif authentication_hash
          Rails.logger.warn ">>> got login request: delegating!"
          response = delegate(authentication_hash.merge(:password => password))
        
        # 3. There is an auth cookie whose token we don't recognise but can pass up to coca masters
        elsif cookie.token
          Rails.logger.warn ">>> got auth_token: delegating!"
          response = delegate({:auth_token => cookie.token})

        else
          Rails.logger.warn ">>> Nothing to do here!"
        end
        
        if response
          Rails.logger.warn ">>> got delegation response: #{response.inspect}"
          # coincidentally, rocket_pants likes to store a rest object under :response
          user_data = response["response"]
          user_data.symbolize_keys!
          resource = mapping.to.where(:uid => user_data[:uid]).first_or_create
          resource.update_attributes(user_data.except(:uid))
          Rails.logger.warn ">>> setting cookie for: #{resource.inspect}"
          cookie.set(resource)
          Rails.logger.warn ">>> cookie: #{cookie.inspect}"
          success!(resource) if resource && resource.persisted?
        end
      end
      
      def delegate(credentials)
        rocket_package = nil
        Coca.masters.each do |master|
          rocket_package = master.authenticate(scope, credentials)
          break if rocket_package
        end
        
        if rocket_package
          # Rocket_pants passes the main REST object as a :response value
          # which leaves us with this bit of dodgy unpacking
          rocket_package.parsed_response
        end
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
