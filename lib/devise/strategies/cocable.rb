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
        
        # 1. there is an auth cookie, it's still valid and we recognise the auth_token it contains
        # The ttl is really a cache parameter: a cookie less old than that we can just accept. 10.minutes is normal.
        
        if cookie.alive? && resource = mapping.to.find_for_token_authentication(:auth_token => cookie.token)
          success!(resource)
        
        # 2. there is an email/password login hash that we can pass up to coca masters
        
        elsif authentication_hash
          response = delegate(authentication_hash.merge(:password => password))
        
        # 3. There is an auth cookie whose token we don't recognise but can pass up to coca masters
        elsif cookie.token
          response = delegate({:auth_token => cookie.token})
        end
        
        if response
          user_data = response
          resource = mapping.to.where(:uid => user_data['uid']).first_or_create
          updated_columns = (user_data.except('uid') & mapping.to.column_names).symbolize_keys
          resource.update_attributes(updated_columns)
          success!(resource) if resource && resource.persisted?
          # Cookie-setting (and deleting) is handled by warden post-hooks defined in coca.rb
        end
      end
      
      def delegate(credentials)
        package = nil
        Coca.masters.each do |master|
          package = master.authenticate(scope, credentials)
          break if package
        end
        Coca.signer.decode(package) if package
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
