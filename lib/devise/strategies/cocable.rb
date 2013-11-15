require 'devise/strategies/token_authenticatable'
require 'devise/models/cocable'

module Devise
  module Strategies
    
    # The cocable strategy will look for a user in two places: 
    # in a domain cookie set by one of our peers and verified by an upstream app
    # or in credentials supplied to us and verified by an upstream app
    #
    # (If the credentials matched locally, we wouldn't usually get to this strategy)

    class Cocable < Authenticatable
      
      def valid?
        # Coca isn't really a strategy: it delegates the whole process. We don't have an opinion about
        # what parameters should be supplied.
        Coca.masters.any? && valid_for_params_auth? || valid_for_http_auth? || valid_for_cookie_auth?
      end

      def authenticate!
        resource = nil
        response = nil
        
        Coca.log "authenticating"
        
        # 1. there is an auth cookie, it's still valid and we recognise the auth_token it contains
        # The ttl is really a cache parameter: a cookie less old than that we can just accept. 10.minutes is normal.
        
        if cookie.alive? && resource = mapping.to.find_for_token_authentication(:auth_token => cookie.token)
          Coca.log "cookie match: #{cookie.token} -> #{resource.inspect}"
          success!(resource)
        
        # 2. there is an email/password login hash that we can pass up to coca masters
        
        elsif authentication_hash
          credentials = authentication_hash.merge(:password => password)
          Coca.log "authenticating hash #{credentials.inspect}"
          response = delegate(credentials)
        
        # 3. There is an auth cookie whose token we don't recognise but can pass up to coca masters
        elsif cookie.token
          credentials = {:auth_token => cookie.token}
          Coca.log "authenticating token '#{cookie.token}' with masters"
          response = delegate(credentials)
        end
        
        if response
          user_data = response
          Coca.log "user data: #{user_data.inspect})"

          resource = mapping.to.where(:uid => user_data['uid']).first || mapping.to.where(:email => user_data['email']).first || mapping.to.new(:uid => user_data['uid'])
          Coca.log "Local resource: #{resource.inspect}"

          updated_columns = (user_data.except('uid') & mapping.to.column_names).symbolize_keys
          Coca.log "Updating columns: #{updated_columns.inspect}"
          
          if resource.update_attributes(updated_columns)
            resource.confirm! if resource.respond_to?(:confirm!) && !resource.confirmed?
            success!(resource)
            Coca.log "Local resource saved, user signed in"
          else
            Coca.log "User could not be saved. Errors: #{resource.errors.to_a.inspect}"
          end
            
        else
          Coca.log "Not authenticated"
        end
      end
      
      def delegate(credentials)
        package = nil
        Coca.masters.each do |master|
          Coca.log "authenticating with master #{master.name} (#{master.url})"
          package = master.authenticate(scope, credentials)
          Coca.log "     -> #{package.inspect}"
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
